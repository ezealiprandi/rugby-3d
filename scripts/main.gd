extends Node3D
class_name RugbyGame

# ─── Constantes del juego ───────────────────────────────────────────────────
const FIELD_HALF_W := 35.0        # semiancho (touchlines en |x| = 35)
const TRY_Z := 50.0               # líneas de try en |z| = 50
const DEAD_Z := 60.0              # línea de pelota muerta
const TEAM_SIZE := 15
var half_len := 600.0             # segundos por tiempo (opción del menú)
const TACKLE_RANGE := 1.35
const PICKUP_RANGE := 1.4

enum Phase { MENU, KICKOFF, PLAY, BREAKDOWN, SCRUM, LINEOUT, CONVERSION,
	DROPOUT, PENALTY, SCORE, BETWEEN, END, REPLAY, MAUL, PRESENT }

var players: Array[RugbyPlayer] = []
var ball: RugbyBall
var controlled: RugbyPlayer = null
var cam: RugbyCam
var ui: RugbyUI
var menu: RugbyMenu
var referee: RugbyReferee
var field: RugbyField

# modos de juego: "friendly" | "tournament" | "practice"
var mode := "friendly"
var tour_fixture: Array[int] = []
var tour_history: Array = []
var tour_scorers := {}            # nombre → {club, tries}        # resultados por fecha
var sim_log: Array = []             # resultados simulados de la fecha actual
var tour_pos := 0
var tour_wins := 0
var tour_losses := 0
var tour_table: Array = []          # tabla de posiciones de los 12 clubes

var home_idx := 0                  # clubes elegidos en el menú
var away_idx := 1
var score := [0, 0]
var half := 1
var clock := 0.0
var attack_dir := [1, -1]
var phase := Phase.MENU
var phase_t := 0.0
var kick_team := 1
var first_kicker := 1
var last_scoring_team := -1
var pending_team := -1             # equipo favorecido en el próximo restart
var pending_spot := Vector3.ZERO
var ruck_team := -1                # equipo del portador placado (en BREAKDOWN)
var ruck_dir := 1                  # dirección de ataque de ese equipo
var lineout_mark := 0.0
var lineout_side := 1.0
var drop_team := -1
var rng := RandomNumberGenerator.new()

# conversión
enum ConvState { AIM, POWER, FLY, WAIT_AI, DONE }
var conv_state := ConvState.AIM
var conv_team := 0
var conv_dir := 1
var conv_spot_x := 0.0
var conv_kick_pos := Vector3.ZERO
var conv_aim := 0.0
var conv_aim_dir := 1.0
var conv_power := 0.0
var conv_power_dir := 1.0
var conv_prev_z := 0.0
var conv_t := 0.0
var conv_done_flag := false
var conv_kicker: RugbyPlayer = null
var conv_aim_marker: MeshInstance3D   # retícula 3D del objetivo en la H
var conv_trail: MeshInstance3D        # línea de trayectoria ball→objetivo
var conv_height := 0.6                # elevación de la patada (W/S en aim)
const CONV_SWEET_LO := 0.60           # zona verde de la barra de potencia
const CONV_SWEET_HI := 0.80
var confetti: GPUParticles3D = null
var celebrate_all_team := -1   # todo el equipo festeja (campeón del torneo)

# opciones del menú (persisten en user://settings.cfg)
var opt_difficulty := 1        # 0 fácil · 1 normal · 2 difícil
var opt_tod := "random"        # random · day · sunset · night
var opt_weather := "random"    # random · clear · rain
var opt_sound := true
var opt_quality := 2           # 0 baja · 1 media · 2 alta
var opt_fullscreen := false
var opt_vsync := true
var opt_volume := 4            # 0..4 → mudo..100%
var opt_sprint_toggle := false # false mantener · true alternar
var opt_game_speed := 1.0      # 1.0 · 0.75 · 0.5 (accesibilidad)
var opt_selmode := 1           # 0 automática · 1 mixta · 2 manual (click)
var sel_cd := 0.0              # cooldown mínimo entre cambios de jugador
var opt_ui_big := false        # interfaz más grande
var opt_lang := "es"           # es · en
const RES_MODES := [[1280, 720, "1280×720"], [1366, 768, "1366×768"],
	[1600, 900, "1600×900"], [1920, 1080, "1920×1080"]]
var opt_resolution := 2        # índice en RES_MODES
var last_champion := -1        # índice del último campeón del torneo
var conv_pts := 2                     # 2 conversión · 3 penal a los palos

# drop goal en juego abierto
var drop_goal_team := -1
var drop_prev_z := 0.0

# disciplina
var pen_count := [0, 0]
var celebrating: RugbyPlayer = null

# replay broadcast del try
const REPLAY_LEN := 540                # frames grabados (~9s, la jugada entera)
var replay_buf: Array = []
var replay_i := 0
var replay_wait := 0.0                 # espera antes de reproducir (intro animada)

const POS_NAMES := ["Pilar", "Hooker", "Pilar", "Segunda", "Segunda",
	"Flanker", "Flanker", "Octavo", "Medioscrum", "Apertura", "Wing",
	"Centro", "Centro", "Wing", "Fullback"]

# maul
var maul_team := -1
var maul_dir := 1.0
var pending_maul_team := -1   # se arma cuando el catcher agarra el lineout
var jackal_pressed := false
var settle_t := 0.0                  # defensores aguantan tras el ruck
var opt_camera := 0                  # 0 broadcast · 1 cercana · 2 lejana  # el jugador apretó F para competir en el ruck
var offload_t := 0.0          # ventana para soltar la pelota al ser placado
var offloader: RugbyPlayer = null  # el jugador apretó F para competir en el ruck

# forcejeo post-placaje: machacar ESPACIO (retenés) o barra de timing (robás)
var contest_carrier: RugbyPlayer = null
var contest_steal := false      # false = te placaron y retenés · true = placaste y robás
var contest_mash := false       # true = machacar ESPACIO · false = barra de timing
var contest_prompt := false     # esperando F para arrancar el forcejeo de robo
var contest_active := false     # minijuego corriendo
var contest_t := 0.0            # tiempo límite
var contest_total := 5.0        # duración del forcejeo (para la barra)
var contest_hits := 0
var contest_need := 5
var contest_cursor := 0.0
var contest_sway := 1.0
var contest_speed := 1.0
var contest_zone := Vector2(0.5, 0.82)
var crowd_boost := 0.0        # sube el volumen de la tribuna un momento

# ventaja del árbitro
var adv_t := -1.0
var adv_team := -1
var adv_spot := Vector3.ZERO
var adv_hold := 0.0
var total_pens := [0, 0]       # penales acumulados por equipo (amarilla/roja)  # el jugador apretó F para competir en el ruck

# clima y estadísticas
var weather := "clear"
var poss_t := [0.0, 0.0]
var tries_n := [0, 0]
var tackles_n := [0, 0]

# audio
var sfx_whistle: AudioStreamPlayer
var sfx_crowd: AudioStreamPlayer
var sfx_cheer: AudioStreamPlayer
var sfx_rain: AudioStreamPlayer
var sfx_steps: AudioStreamPlayer
var sfx_tackle: AudioStreamPlayer
var sfx_slide: AudioStreamPlayer
var sfx_kick: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_register_input()
	field = RugbyField.build(self)
	field.process_mode = Node.PROCESS_MODE_PAUSABLE
	_spawn_ball()
	ball.global_position = Vector3(0.0, 0.6, 0.0)
	cam = RugbyCam.new()
	cam.game = self
	cam.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cam)
	ui = RugbyUI.new()
	ui.game = self
	add_child(ui)
	menu = RugbyMenu.new()
	menu.game = self
	add_child(menu)
	sfx_whistle = _mk_audio("res://assets/whistle.wav", -6.0)
	sfx_crowd = _mk_audio("res://assets/crowd.wav", -5.0)
	sfx_cheer = _mk_audio("res://assets/cheer.wav", -4.0)
	sfx_rain = _mk_audio("res://assets/rain.wav", -18.0)
	sfx_steps = _mk_audio("res://assets/steps.wav", -14.0)
	sfx_tackle = _mk_audio("res://assets/tackle.wav", -8.0)
	sfx_slide = _mk_audio("res://assets/slide.wav", -9.0)
	sfx_kick = _mk_audio("res://assets/kick.wav", -6.0)
	ui.set_info("WASD mover · Shift sprint · Espacio pasar · K patada · Esc pausa")
	ui.visible = false
	_load_options()
	menu.start()
	# flag de desarrollo: --auto salta el menú y arranca un partido
	if "--auto" in OS.get_cmdline_user_args() or "--auto" in OS.get_cmdline_args():
		menu.hide_menu()
		start_match(0, 1)


# ─── Input ──────────────────────────────────────────────────────────────────
func _register_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("sprint", [KEY_SHIFT])
	_add_key_action("pass", [KEY_SPACE])
	_add_key_action("pass_left", [KEY_Q])
	_add_key_action("pass_right", [KEY_E])
	_add_key_action("tackle", [KEY_F])
	_add_key_action("grubber", [KEY_C])
	_add_key_action("bomb", [KEY_V])
	_add_key_action("step", [KEY_X])
	_add_key_action("crosskick", [KEY_Z])
	_add_key_action("touchkick", [KEY_T])
	_add_key_action("dummy", [KEY_B])
	_add_key_action("kick", [KEY_K])
	_add_key_action("dropgoal", [KEY_G])
	_add_key_action("fend", [KEY_J])
	_add_key_action("confirm", [KEY_ENTER, KEY_KP_ENTER])
	_add_key_action("restart", [KEY_R])
	_add_key_action("menu", [KEY_M])
	_add_key_action("pause", [KEY_ESCAPE, KEY_P])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func save_options() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "difficulty", opt_difficulty)
	cfg.set_value("game", "tod", opt_tod)
	cfg.set_value("game", "weather", opt_weather)
	cfg.set_value("game", "sound", opt_sound)
	cfg.set_value("game", "half_len", half_len)
	cfg.set_value("game", "quality", opt_quality)
	cfg.set_value("game", "camera", opt_camera)
	cfg.set_value("game", "fullscreen", opt_fullscreen)
	cfg.set_value("game", "vsync", opt_vsync)
	cfg.set_value("game", "volume", opt_volume)
	cfg.set_value("game", "sprint_toggle", opt_sprint_toggle)
	cfg.set_value("game", "game_speed", opt_game_speed)
	cfg.set_value("game", "selmode", opt_selmode)
	cfg.set_value("game", "ui_big", opt_ui_big)
	cfg.set_value("game", "lang", opt_lang)
	cfg.set_value("game", "resolution", opt_resolution)
	cfg.save("user://settings.cfg")
	_apply_options()


func _load_options() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		opt_difficulty = cfg.get_value("game", "difficulty", 1)
		opt_tod = cfg.get_value("game", "tod", "random")
		opt_weather = cfg.get_value("game", "weather", "random")
		opt_sound = cfg.get_value("game", "sound", true)
		half_len = cfg.get_value("game", "half_len", 600.0)
		opt_quality = cfg.get_value("game", "quality", 2)
		opt_camera = cfg.get_value("game", "camera", 0)
		opt_fullscreen = cfg.get_value("game", "fullscreen", false)
		opt_vsync = cfg.get_value("game", "vsync", true)
		opt_volume = cfg.get_value("game", "volume", 4)
		opt_sprint_toggle = cfg.get_value("game", "sprint_toggle", false)
		opt_game_speed = cfg.get_value("game", "game_speed", 1.0)
		opt_selmode = int(cfg.get_value("game", "selmode", 1))
		opt_ui_big = cfg.get_value("game", "ui_big", false)
		opt_lang = cfg.get_value("game", "lang", "es")
		opt_resolution = clampi(int(cfg.get_value("game", "resolution", 2)),
			0, RES_MODES.size() - 1)
		last_champion = cfg.get_value("records", "champion", -1)
	_apply_options()


func _apply_options() -> void:
	AudioServer.set_bus_mute(0, not opt_sound)
	AudioServer.set_bus_volume_db(0, [-80.0, -18.0, -10.0, -5.0, 0.0][opt_volume])
	Engine.time_scale = opt_game_speed
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if opt_vsync else DisplayServer.VSYNC_DISABLED)
	if opt_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		# en fullscreen: usar la resolución elegida como content_scale
		# (la ventana ocupa toda la pantalla pero el render escala a la resolución)
		var rw: int = RES_MODES[opt_resolution][0]
		var rh: int = RES_MODES[opt_resolution][1]
		get_window().content_scale_size = Vector2i(rw, rh)
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var scr := DisplayServer.screen_get_size()
		var rw: int = RES_MODES[opt_resolution][0]
		var rh: int = RES_MODES[opt_resolution][1]
		get_window().size = Vector2i(mini(rw, scr.x), mini(rh, scr.y - 48))
		get_window().position = (scr - get_window().size) / 2
	get_window().content_scale_factor = 1.22 if opt_ui_big else 1.0
	if not opt_fullscreen:
		get_window().content_scale_size = Vector2i.ZERO
	if field != null and field.env_node != null:
		var e := field.env_node.environment
		e.glow_enabled = opt_quality >= 1
		e.ssao_enabled = opt_quality >= 2


func _mk_audio(path: String, db: float) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.volume_db = db
	if ResourceLoader.exists(path):
		a.stream = load(path)
	add_child(a)
	return a


func _kick_sfx() -> void:
	if sfx_kick.stream != null:
		sfx_kick.play()


func _whistle() -> void:
	if sfx_whistle.stream != null:
		sfx_whistle.play()


# ─── Setup ──────────────────────────────────────────────────────────────────
func _spawn_ball() -> void:
	ball = RugbyBall.new()
	ball.game = self
	ball.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ball)


func _spawn_players() -> void:
	for p in players:
		p.queue_free()
	players.clear()
	var clubs: Array = RugbyTeams.CLUBS
	# choque de camisetas → el visitante usa kit alternativo (color de la banda)
	var hp: Color = clubs[home_idx]["primary"]
	var ap: Color = clubs[away_idx]["primary"]
	var clash := Vector3(hp.r - ap.r, hp.g - ap.g, hp.b - ap.b).length() < 0.45
	for team in 2:
		var club_idx: int = home_idx if team == 0 else away_idx
		var club: Dictionary = clubs[club_idx]
		var use_alt := team == 1 and clash
		for i in TEAM_SIZE:
			var p := RugbyPlayer.new()
			p.game = self
			p.team = team
			p.index = i
			p.rating = club["rating"] * \
				([0.9, 1.0, 1.12][opt_difficulty] if team == 1 else 1.0)
			# stats por posición: forwards fuertes/lentos, backs rápidos
			match i:
				0, 1, 2:   p.speed_mult = 0.84; p.break_prob = 0.30   # front row
				3, 4:      p.speed_mult = 0.90; p.break_prob = 0.28   # locks
				5, 6, 7:   p.speed_mult = 0.95; p.break_prob = 0.32   # back row
				8:         p.speed_mult = 1.04; p.break_prob = 0.08   # medio scrum
				9:         p.speed_mult = 1.02; p.break_prob = 0.06   # apertura
				10, 13:    p.speed_mult = 1.08; p.break_prob = 0.12   # centros
				11, 14:    p.speed_mult = 1.16; p.break_prob = 0.04   # wings
				12:        p.speed_mult = 1.14; p.break_prob = 0.05   # fullback
			p.col_primary = club["primary"]
			p.col_secondary = club["secondary"]
			p.col_shorts = club["shorts"]
			p.alt_kit = use_alt
			p.jersey_tex = RugbyTeams.jersey_texture(club_idx, use_alt)
			p.jersey_tex_alt = p.jersey_tex
			p.pname = RugbyTeams.SQUADS[club_idx][i]
			p.process_mode = Node.PROCESS_MODE_PAUSABLE
			add_child(p)
			players.append(p)
	# árbitro + jueces de touch
	if referee == null:
		referee = RugbyReferee.new()
		referee.game = self
		referee.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(referee)
		referee.build_match()
	referee.global_position = Vector3(4.0, 0.0, -8.0)


func start_match(home: int, away: int, m := "friendly") -> void:
	mode = m
	home_idx = home
	ui.visible = true
	score = [0, 0]
	half = 1
	clock = 0.0
	attack_dir = [1, -1]
	pen_count = [0, 0]
	total_pens = [0, 0]
	adv_t = -1.0
	adv_team = -1
	adv_hold = 0.0
	drop_goal_team = -1
	celebrating = null
	poss_t = [0.0, 0.0]
	tries_n = [0, 0]
	tackles_n = [0, 0]
	pending_maul_team = -1
	maul_team = -1
	ui.hide_stats()
	replay_buf.clear()
	if opt_weather == "random":
		weather = "rain" if rng.randf() < 0.3 else "clear"
	else:
		weather = opt_weather
	var tod := opt_tod
	if tod == "random":
		var tod_roll := rng.randf()
		tod = "day" if tod_roll < 0.4 else \
			("sunset" if tod_roll < 0.75 else "night")
	if field != null:
		field.set_daytime(tod)
		field.set_weather(weather == "rain")
	first_kicker = rng.randi() % 2   # moneda al aire
	if sfx_crowd.stream != null:
		# cada club suena un poco distinto: su hinchada tiene su tono
		sfx_crowd.pitch_scale = 0.94 + (home % 6) * 0.035
		sfx_crowd.volume_db = -5.0
		crowd_boost = 0.0
		if not sfx_crowd.playing:
			sfx_crowd.play()
	if mode == "tournament":
		if tour_fixture.is_empty():
			# fixture del torneo: del rival más débil al más fuerte
			var rest: Array[int] = []
			for i in RugbyTeams.CLUBS.size():
				if i != home:
					rest.append(i)
			rest.sort_custom(func(a, b):
				return RugbyTeams.CLUBS[a]["rating"] < RugbyTeams.CLUBS[b]["rating"])
			tour_fixture = rest
			tour_pos = 0
			tour_wins = 0
			tour_losses = 0
			tour_table.clear()
			tour_history.clear()
			tour_scorers.clear()
			for i in RugbyTeams.CLUBS.size():
				tour_table.append({"pts": 0, "played": 0, "won": 0,
					"drawn": 0, "lost": 0, "pf": 0, "pa": 0, "bonus": 0})
		away = tour_fixture[tour_pos]
	away_idx = away
	ui.show_vs(home_idx, away_idx)
	ui.tv_show(true)
	ui.motm_hide()
	ui.presenter_show(home_idx, away_idx)
	ui.lineup_show(home_idx, away_idx)
	ui.flash_hint("WASD moverse · Q/E pase · F placaje · K/C/V/Z patadas · Shift sprint", 5.0)
	ui.set_teams(home_idx, away_idx)
	if field != null:
		field.tint_crowd(RugbyTeams.CLUBS[home_idx]["primary"],
			RugbyTeams.CLUBS[away_idx]["primary"])
	_spawn_players()
	reset_for_kickoff(first_kicker)
	phase = Phase.PRESENT            # formación lista; orbitamos el estadio
	phase_t = 4.2
	ui.commentary("Moneda al aire: %s pone la pelota en juego"
		% _club_name(first_kicker))
	var tod_msg := ""
	match tod:
		"day": tod_msg = "Tarde de sol en Tucumán"
		"night": tod_msg = "¡Noche de rugby! Los focos prendidos"
		_: tod_msg = "Atardecer en Tucumán"
	if weather == "rain":
		ui.show_message("🌧 Lluvia en Tucumán — la pelota resbala", 3.0)
		if sfx_rain.stream != null and not sfx_rain.playing:
			sfx_rain.play()
	elif sfx_rain.playing:
		sfx_rain.stop()
	else:
		ui.show_message(tod_msg, 2.2)
	if mode == "tournament":
		ui.show_message("TORNEO URT · Fecha %d/%d · %s vs %s" %
			[tour_pos + 1, tour_fixture.size(), _club_name(0), _club_name(1)], 3.0)


func return_to_menu() -> void:
	if ui != null:
		ui.tv_show(false)
	for p in players:
		p.queue_free()
	players.clear()
	controlled = null
	celebrate_all_team = -1
	ball.release()
	ball.freeze = true
	ball.global_position = Vector3(0.0, 0.6, 0.0)
	cam.clear_override()
	ui.conv_hide()
	ui.visible = false
	phase = Phase.MENU
	tour_fixture.clear()
	if sfx_crowd.playing:
		sfx_crowd.stop()
	menu.start()


func _club_name(team: int) -> String:
	return RugbyTeams.CLUBS[home_idx if team == 0 else away_idx]["abbr"]


func reset_for_kickoff(kt: int) -> void:
	phase = Phase.KICKOFF
	phase_t = 1.0
	kick_team = kt
	var kd := float(attack_dir[kt])
	for p in players:
		p.tackled = 0.0
		p.cool_pass = 0.0
		p.velocity = Vector3.ZERO
		var pos := Vector3.ZERO
		if p.team == kt:
			# equipo que saca: detrás de la mitad de cancha
			if p.index == 9:
				pos = Vector3(0.0, 0.0, -kd * 1.2)              # apertura patea
			elif p.index < 8:
				pos = Vector3(-21.0 + p.index * 6.0, 0.0, -kd * 4.0)
			else:
				pos = Vector3(-18.0 + (p.index - 8) * 5.0, 0.0, -kd * 9.0)
		else:
			# receptores desplegados en su campo
			var rx := [-8.0, 8.0, 0.0, -16.0, 16.0, -24.0, 24.0, -2.0,
				4.0, 0.0, -28.0, 28.0, -12.0, 12.0, 0.0]
			var rz := [34.0, 34.0, 30.0, 36.0, 36.0, 40.0, 40.0, 28.0,
				26.0, 44.0, 46.0, 46.0, 48.0, 48.0, 42.0]
			pos = Vector3(rx[p.index], 0.0, kd * rz[p.index])
		p.global_position = pos
		p.hold_pos = pos
		p.facing = Vector3(0.0, 0.0, kd if p.team == kt else -kd)
		p.visual.rotation.y = atan2(p.facing.x, p.facing.z)
	ball.release()
	ball.global_position = Vector3(0.0, 0.9, -kd * 1.2)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = true
	_select_controlled()
	ui.show_message("¡Saque de %s!" % _club_name(kt), 1.6)


func _do_kickoff() -> void:
	_whistle()
	var kd := float(attack_dir[kick_team])
	ball.release()
	ball.global_position = Vector3(0.0, 0.9, -kd * 1.2)
	var target := Vector3(rng.randf_range(-14.0, 14.0), 0.0, kd * rng.randf_range(30.0, 40.0))
	var diff := target - ball.global_position
	var t := clampf(Vector2(diff.x, diff.z).length() / 19.0, 1.6, 2.4)
	ball.linear_velocity = Vector3(diff.x / t, (diff.y + 4.9 * t * t) / t, diff.z / t)
	ball.angular_velocity = Vector3(kd, 0.0, 0.0) * 10.0
	ball.release_guard = 0.35
	ball.last_touch_team = kick_team
	_kick_sfx()
	phase = Phase.PLAY
	ui.show_message("¡A jugar!", 1.4)


# ─── Loop principal ─────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT and not get_tree().paused:
		_click_select(event.position)


func _process(delta: float) -> void:
	var in_menu := phase == Phase.MENU
	if Input.is_action_just_pressed("pause") and not in_menu and phase != Phase.END:
		get_tree().paused = not get_tree().paused
		ui.set_paused(get_tree().paused)
	if get_tree().paused:
		return
	if Input.is_action_just_pressed("menu") \
			and (phase == Phase.END or mode == "practice"):
		return_to_menu()
		return
	if Input.is_action_just_pressed("restart") and phase == Phase.END:
		if mode == "tournament":
			_tour_next()
		else:
			start_match(home_idx, away_idx, mode)
		return
	# si el juego cortó a otra fase con un forcejeo abierto, cerrarlo
	if contest_carrier != null and phase != Phase.PLAY:
		_contest_clear()
	# la tribuna vuelve a su nivel luego de una explosión
	if crowd_boost > 0.0:
		crowd_boost = maxf(0.0, crowd_boost - delta * 3.0)
		if sfx_crowd.stream != null:
			sfx_crowd.volume_db = -5.0 + crowd_boost

	match phase:
		Phase.MENU:
			pass
		Phase.PRESENT:
			phase_t -= delta
			if phase_t <= 0.0:
				phase = Phase.KICKOFF
				phase_t = 1.2
				ui.presenter_hide()
		Phase.KICKOFF:
			phase_t -= delta
			if phase_t <= 0.0:
				_do_kickoff()
		Phase.PLAY:
			clock += delta * _clock_speed()
			if settle_t > 0.0:
				settle_t -= delta
			_record_frame()
			if controlled != null and controlled.tackled <= 0.0 					and controlled.velocity.length() > 2.5:
				if sfx_steps.stream != null and not sfx_steps.playing:
					sfx_steps.play()
				sfx_steps.pitch_scale = 					1.15 if controlled.velocity.length() > 8.5 else 0.9
			elif sfx_steps.playing:
				sfx_steps.stop()
			var poss_team: int = ball.carrier.team if ball.carrier != null \
				else ball.last_touch_team
			if poss_team >= 0:
				poss_t[poss_team] += delta
			if contest_carrier != null:
				_contest_update(delta)
			elif offloader != null:
				offload_t -= delta
				if offload_t <= 0.0:
					_begin_breakdown(offloader)
					offloader = null
			if adv_t > 0.0:
				adv_t -= delta
				var ac := ball.carrier
				if ac != null and ac.team == adv_team:
					adv_hold += delta
					if adv_hold > 1.2:
						adv_t = -1.0        # ventaja aprovechada
				elif ac != null and ac.team != adv_team:
					adv_t = -1.0
					_event_scrum(adv_team, adv_spot,
						"Scrum para %s — se acabó la ventaja" % _club_name(adv_team))
				elif adv_t <= 0.0:
					adv_t = -1.0
					_event_scrum(adv_team, adv_spot,
						"¡Scrum para %s! (ventaja no aprovechada)" % _club_name(adv_team))
			if pending_maul_team >= 0 and ball.carrier != null:
				if ball.carrier.team == pending_maul_team:
					_start_maul(pending_maul_team)
				pending_maul_team = -1
			_check_clock()
			_check_boundaries()
		Phase.REPLAY:
			if replay_wait > 0.0:
				replay_wait -= delta
				if replay_wait <= 0.0:
					ui.replay_intro_hide()
					ui.replay_overlay(true)
					# la tribuna reacciona al ver la repetición
					crowd_boost = 4.0
					if sfx_cheer.stream != null:
						sfx_cheer.volume_db = -9.0
						sfx_cheer.pitch_scale = 0.85
						sfx_cheer.play()
			else:
				if Input.is_action_just_pressed("pass"):
					replay_i = replay_buf.size()   # Espacio: saltea el replay
				_replay_step()
		Phase.MAUL:
			_update_maul(delta)
		Phase.BREAKDOWN:
			_record_frame()
			phase_t -= delta
			if Input.is_action_just_pressed("tackle"):
				jackal_pressed = true
			if ruck_team == 0:
				# sos el medioscrum: elegís a dónde abrir
				if Input.is_action_just_pressed("pass_left"):
					_ruck_play(-1)
				elif Input.is_action_just_pressed("pass_right"):
					_ruck_play(1)
				elif Input.is_action_just_pressed("pass"):
					_ruck_play(0)
				elif phase_t <= 0.0:
					_resolve_breakdown()
			elif phase_t <= 0.0:
				_resolve_breakdown()
		Phase.SCRUM:
			# los packs empujan: el scrum gana metros
			pending_spot.z += float(attack_dir[pending_team]) * 1.3 * delta
			pending_spot.z = clampf(pending_spot.z, -TRY_Z + 6.0, TRY_Z - 6.0)
			if pending_team == 0:
				if Input.is_action_just_pressed("pass_left"):
					_scrum_play(-1)
				elif Input.is_action_just_pressed("pass_right"):
					_scrum_play(1)
				elif Input.is_action_just_pressed("pass"):
					_scrum_play(0)
				else:
					phase_t -= delta * 0.4   # más tiempo para decidir
				if phase_t <= 0.0:
					_resolve_scrum()
			else:
				phase_t -= delta
				if phase_t <= 0.0:
					_resolve_scrum()
		Phase.LINEOUT:
			if pending_team == 0:
				if Input.is_action_just_pressed("pass_left"):
					_lineout_play(0)
				elif Input.is_action_just_pressed("pass_right"):
					_lineout_play(1)
				elif Input.is_action_just_pressed("pass"):
					_lineout_play(2)
				else:
					phase_t -= delta * 0.5
				if phase_t <= 0.0:
					_resolve_lineout()
			else:
				phase_t -= delta
				if phase_t <= 0.0:
					_resolve_lineout()
		Phase.PENALTY:
			phase_t -= delta
			if pending_team == 0:
				# el jugador decide: tap (Espacio), palos (K) o al touch (T)
				if _pen_in_range() and Input.is_action_just_pressed("kick"):
					_setup_penalty_goal()
				elif Input.is_action_just_pressed("touchkick"):
					_pen_touch_kick()
				elif Input.is_action_just_pressed("pass") or phase_t <= 0.0:
					_resolve_penalty()
			elif phase_t <= 0.0:
				_resolve_penalty()
		Phase.DROPOUT:
			phase_t -= delta
			if phase_t <= 0.0:
				_resolve_dropout()
		Phase.CONVERSION:
			_update_conversion(delta)
		Phase.SCORE:
			phase_t -= delta
			if phase_t <= 0.0:
				_setup_conversion()
		Phase.BETWEEN:
			phase_t -= delta
			if phase_t <= 0.0:
				reset_for_kickoff(1 - first_kicker)
		Phase.END:
			pass

	if not in_menu:
		_select_controlled()
		_refresh_ui()


# reloj acelerado tipo FIFA: cada tiempo se completa en ~5 min reales
func _clock_speed() -> float:
	return half_len / 300.0 if half_len > 300.0 else 1.0


func _check_clock() -> void:
	if clock < half_len or mode == "practice":
		return
	if half == 1:
		half = 2
		clock = 0.0
		attack_dir = [-attack_dir[0], -attack_dir[1]]
		phase = Phase.BETWEEN
		phase_t = 3.0
		_whistle()
		var htot: float = poss_t[0] + poss_t[1]
		var hposs := ""
		if htot > 1.0:
			hposs = " · Posesión %d%%-%d%%" % [
				int(poss_t[0] / htot * 100), int(poss_t[1] / htot * 100)]
		ui.show_message("¡Entretiempo! Cambian de campo" + hposs, 2.8)
		# stats del primer tiempo, estilo transmisión
		var hstats := "1T — %s %d · %d %s   ·   Tries %d-%d   ·   Placajes %d-%d" % [
			RugbyTeams.CLUBS[home_idx]["abbr"], score[0], score[1],
			RugbyTeams.CLUBS[away_idx]["abbr"],
			tries_n[0], tries_n[1], tackles_n[0], tackles_n[1]]
		var htot2: float = poss_t[0] + poss_t[1]
		if htot2 > 1.0:
			hstats += "   ·   Posesión %d%%-%d%%" % [
				int(poss_t[0] / htot2 * 100), int(poss_t[1] / htot2 * 100)]
		ui.ht_show(hstats)
		# ingresan los suplentes: piernas frescas en ambos equipos
		for p in players:
			p.stamina = 1.0
		ui.commentary("Movimiento en los bancos: entra sangre fresca")
	else:
		phase = Phase.END
		_whistle()
		var total: float = poss_t[0] + poss_t[1]
		var poss_pct := ""
		if total > 1.0:
			poss_pct = " · Posesión %d%%-%d%%" % [
				int(poss_t[0] / total * 100), int(poss_t[1] / total * 100)]
		var stats := "%s · Tries %d-%d · Placajes %d-%d" % [
			poss_pct, tries_n[0], tries_n[1], tackles_n[0], tackles_n[1]]
		var mvp := ""
		var bt := 0
		var bk := 0
		for p in players:
			if p.stat_tries > bt:
				bt = p.stat_tries
				mvp = " · MVP tries: %s #%d (%d)" % [p.pname, p.index + 1,
					p.stat_tries]
			if p.stat_tackles > bk:
				bk = p.stat_tackles
		if bt > 0:
			stats += mvp
		var table_txt := ""
		if mode == "tournament":
			if score[0] > score[1]:
				tour_wins += 1
			elif score[0] < score[1]:
				tour_losses += 1
			_record_result(home_idx, away_idx, score[0], score[1],
				tries_n[0], tries_n[1])
			sim_log.clear()
			sim_log.append("%s %d-%d %s" % [
				RugbyTeams.CLUBS[home_idx]["abbr"], score[0],
				score[1], RugbyTeams.CLUBS[away_idx]["abbr"]])
			_sim_fecha()
			tour_history.append(sim_log.duplicate())
			table_txt = "\n\n" + _table_text()
			# última fecha y campeón → festejo del equipo entero
			if tour_pos >= tour_fixture.size() - 1 \
					and _table_order()[0] == home_idx:
				last_champion = home_idx
				var ccfg := ConfigFile.new()
				ccfg.load("user://settings.cfg")
				ccfg.set_value("records", "champion", home_idx)
				ccfg.save("user://settings.cfg")
				celebrate_all_team = 0
				_confetti(players[0].global_position,
					RugbyTeams.CLUBS[home_idx]["primary"])
				ui.show_message("¡¡SOS CAMPEÓN DEL TORNEO URT!!", 999.0)
			if celebrate_all_team < 0:
				ui.show_message(
					"FINAL · %s %d — %d %s · Torneo %dG-%dP%s · R fecha siguiente · M menú"
					% [_club_name(0), score[0], score[1], _club_name(1),
					tour_wins, tour_losses, stats], 999.0)
		else:
			ui.show_message("FINAL · %s %d — %d %s%s · R revancha · M menú" %
				[_club_name(0), score[0], score[1], _club_name(1), stats], 999.0)
		if celebrate_all_team < 0:
			ui.show_stats(_build_stats_text(poss_pct) + table_txt)
			var mvp_p: RugbyPlayer = null
			var mvp_s := -1.0
			for p in players:
				var s := p.stat_tries * 10.0 + p.stat_tackles * 1.0 					+ p.stat_metros * 0.08
				if s > mvp_s:
					mvp_s = s
					mvp_p = p
			if mvp_p != null and mvp_s > 0.5:
				ui.motm_show(mvp_p)


func _check_boundaries() -> void:
	if ball.carrier != null:
		var c: RugbyPlayer = ball.carrier
		var cp := c.global_position
		var d := float(attack_dir[c.team])
		if cp.z * d > TRY_Z and absf(cp.x) <= FIELD_HALF_W + 1.0:
			_on_try(c.team)
			return
		if cp.z * d < -TRY_Z:
			# se refugió en su propio in-goal → drop-out 22
			_event_dropout(c.team, "¡In-goal propio! Drop-out de 22 para %s" % _club_name(c.team))
			return
		if absf(cp.x) > FIELD_HALF_W:
			_event_lineout(1 - c.team, cp.z, signf(cp.x),
				"¡Touch! Lineout para %s" % _club_name(1 - c.team))
	else:
		var bp := ball.global_position
		# drop goal: ¿cruzó los palos por arriba del travesaño?
		if drop_goal_team >= 0:
			var dd := float(attack_dir[drop_goal_team])
			var was := (drop_prev_z - dd * TRY_Z) * dd
			var now := (bp.z - dd * TRY_Z) * dd
			drop_prev_z = bp.z
			if was < 0.0 and now >= 0.0:
				var scored := absf(bp.x) <= 2.8 and bp.y >= 3.0
				var t3 := drop_goal_team
				drop_goal_team = -1
				if scored:
					score[t3] += 3
					ui.show_message("¡DROP GOAL! +3 para %s" % _club_name(t3), 2.4)
					if sfx_cheer.stream != null:
						sfx_cheer.play()
					reset_for_kickoff(1 - t3)
				return
			if ball.carrier != null or bp.y < 0.3:
				drop_goal_team = -1
		if absf(bp.x) > FIELD_HALF_W + 0.3:
			var recv := 1 - ball.last_touch_team if ball.last_touch_team >= 0 else 0
			_event_lineout(recv, bp.z, signf(bp.x),
				"¡Touch! Lineout para %s" % _club_name(recv))
		elif absf(bp.z) > DEAD_Z:
			# pelota muerta → drop-out del equipo que defiende ese in-goal
			var def_team := 0 if float(attack_dir[0]) * signf(bp.z) < 0.0 else 1
			_event_dropout(def_team, "¡Pelota muerta! Drop-out de 22 para %s" % _club_name(def_team))


func _record_frame() -> void:
	var f := []
	for p in players:
		f.append(p.global_position)
	for p in players:
		f.append(p.visual.rotation.y if p.visual != null else 0.0)
	# animación de limbs para que el replay no muestre jugadores "congelados"
	for p in players:
		f.append(p.leg_l.rotation.x if p.leg_l != null else 0.0)
		f.append(p.leg_r.rotation.x if p.leg_r != null else 0.0)
		f.append(p.arm_l.rotation.x if p.arm_l != null else 0.0)
		f.append(p.arm_r.rotation.x if p.arm_r != null else 0.0)
		f.append(p.visual.rotation.x if p.visual != null else 0.0)
		f.append(p.visual.position.y if p.visual != null else 0.0)
	f.append(ball.global_position)
	replay_buf.append(f)
	if replay_buf.size() > REPLAY_LEN:
		replay_buf.pop_front()


func _replay_step() -> void:
	if replay_i >= replay_buf.size() - 1:
		phase = Phase.SCORE
		phase_t = 2.0
		ui.replay_overlay(false)
		return
	var f: Array = replay_buf[replay_i]
	replay_i += 1
	var n := players.size()
	for i in n:
		players[i].global_position = f[i]
		if players[i].visual != null:
			players[i].visual.rotation.y = f[n + i]
		# restaurar pose de limbs grabada
		var base := n * 2 + i * 6
		if players[i].leg_l != null:
			players[i].leg_l.rotation.x = f[base]
			players[i].leg_r.rotation.x = f[base + 1]
			players[i].arm_l.rotation.x = f[base + 2]
			players[i].arm_r.rotation.x = f[base + 3]
			players[i].visual.rotation.x = f[base + 4]
			players[i].visual.position.y = f[base + 5]
	ball.global_position = f[n * 8]


func _on_try(team: int) -> void:
	adv_t = -1.0
	score[team] += 5
	tries_n[team] += 1
	last_scoring_team = team
	conv_spot_x = ball.carrier.global_position.x
	var scorer := ball.carrier
	if scorer != null:
		scorer.stat_tries += 1
	celebrating = scorer
	if scorer != null:
		scorer.try_dive_t = 1.1
		if sfx_slide.stream != null:
			sfx_slide.play()
	if replay_buf.size() > 30:
		phase = Phase.REPLAY
		replay_i = 0
		replay_wait = 3.0
		ui.replay_intro_show()
	else:
		phase = Phase.SCORE
		phase_t = 2.0
	ball.release()
	if scorer != null:
		ball.global_position = scorer.global_position + Vector3(0, 0.3, 0)
		scorer.tackled = 0.0
	for p in players:
		p.tackled = 0.0
	_whistle()
	if sfx_cheer.stream != null:
		sfx_cheer.volume_db = -4.0
		sfx_cheer.pitch_scale = 1.0
		sfx_cheer.play()
	if field != null:
		field.crowd_surge()
	_confetti(scorer.global_position,
		RugbyTeams.CLUBS[home_idx if team == 0 else away_idx]["primary"])
	var scorer_txt := ""
	if scorer != null:
		scorer_txt = "#%d %s · " % [scorer.index + 1, scorer.pname]
	var tries_txt := ["¡Qué corrida! Apoya entre los palos",
		"¡Rompe la línea y se va al try!",
		"¡No lo paró nadie en el cierre!",
		"Apoyo perfecto — try colectivo"]
	ui.commentary(scorer_txt + tries_txt[rng.randi() % tries_txt.size()])
	if scorer != null:
		ui.scorer_show(scorer)
		if mode == "tournament":
			var k: String = scorer.pname + "·" + String(RugbyTeams.CLUBS[
				home_idx if scorer.team == 0 else away_idx]["abbr"])
			if not tour_scorers.has(k):
				tour_scorers[k] = 0
			tour_scorers[k] += 1
	if phase == Phase.REPLAY:
		ui.show_message("¡¡¡TRY de %s!!! +5 · REPLAY" % _club_name(team), 2.6)
	else:
		ui.show_message("¡¡¡TRY de %s!!! +5" % _club_name(team), 2.2)


# ─── Patada a los palos estilo Rugby 25 (conversión +2 · penal +3) ──────────
func _setup_conversion() -> void:
	var kx := clampf(conv_spot_x, -30.0, 30.0)
	var d := int(attack_dir[last_scoring_team])
	_setup_kick_at_goal(2, last_scoring_team,
		Vector3(kx, 0.0, d * (TRY_Z - 14.0)))


func _setup_penalty_goal() -> void:
	_setup_kick_at_goal(3, pending_team, pending_spot)


func _setup_kick_at_goal(pts: int, team: int, spot: Vector3) -> void:
	conv_pts = pts
	conv_team = team
	conv_dir = int(attack_dir[conv_team])
	conv_spot_x = spot.x
	conv_kick_pos = spot
	celebrating = null
	# ubicar al pateador (apertura idx 9 o el más cercano disponible)
	var kicker := players[9 + conv_team * TEAM_SIZE]
	if kicker.tackled > 0.0:
		kicker = _nearest(conv_team, conv_kick_pos, null, 999.0)
	conv_kicker = kicker
	kicker.global_position = conv_kick_pos - Vector3(0, 0, conv_dir * 2.0)
	kicker.facing = Vector3(0, 0, conv_dir)
	kicker.hold_pos = kicker.global_position
	kicker.marker.visible = true       # marcar al pateador
	for p in players:
		if p != kicker:
			p.hold_pos = Vector3(clampf(p.global_position.x, -30, 30), 0.0,
				clampf(p.global_position.z, -46, 46))
	ball.freeze = true
	ball.global_position = conv_kick_pos + Vector3(0, 0.2, 0)
	ball.linear_velocity = Vector3.ZERO
	# retícula 3D del objetivo entre los palos + línea de trayectoria
	if conv_aim_marker == null:
		conv_aim_marker = MeshInstance3D.new()
		var am := SphereMesh.new()
		am.radius = 0.28
		am.height = 0.56
		conv_aim_marker.mesh = am
		var amat := StandardMaterial3D.new()
		amat.albedo_color = Color(1.0, 0.85, 0.1)
		amat.emission_enabled = true
		amat.emission = Color(1.0, 0.75, 0.1)
		amat.emission_energy_multiplier = 3.0
		conv_aim_marker.material_override = amat
		add_child(conv_aim_marker)
		var tl := MeshInstance3D.new()
		var tlm := BoxMesh.new()
		tlm.size = Vector3(0.07, 0.07, 1.0)
		tl.mesh = tlm
		var tlmat := StandardMaterial3D.new()
		tlmat.albedo_color = Color(1.0, 0.9, 0.3, 0.55)
		tlmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tlmat.emission_enabled = true
		tlmat.emission = Color(1.0, 0.85, 0.2)
		tlmat.emission_energy_multiplier = 1.4
		conv_trail = tl
		conv_trail.material_override = tlmat
		add_child(conv_trail)
	conv_aim_marker.visible = conv_team == 0
	conv_trail.visible = conv_team == 0
	# cámara centrada y medio alejada: ve al pateador y los palos
	cam.set_override(Vector3(0, 7.0, -conv_dir * 20.0),
		Vector3(0, 3.0, conv_dir * TRY_Z))
	phase = Phase.CONVERSION
	conv_done_flag = false
	if conv_team == 0:
		conv_state = ConvState.AIM
		conv_aim = 0.0
		ui.conv_show()
		ui.conv_set_instr("A/D dirección · W/S altura · ESPACIO potencia")
	else:
		conv_state = ConvState.WAIT_AI
		conv_t = 1.6


func _update_conversion(delta: float) -> void:
	match conv_state:
		ConvState.AIM:
			# aim directo con A/D: mueve la retícula sobre la línea de gol
			if Input.is_action_pressed("move_left"):
				conv_aim -= delta * 0.9
			if Input.is_action_pressed("move_right"):
				conv_aim += delta * 0.9
			# W/S ajusta la elevación de la patada
			if Input.is_action_pressed("move_up"):
				conv_height = minf(conv_height + delta * 0.8, 1.0)
			if Input.is_action_pressed("move_down"):
				conv_height = maxf(conv_height - delta * 0.8, 0.0)
			conv_aim = clampf(conv_aim, -1.0, 1.0)
			ui.conv_set_aim(conv_aim)
			ui.conv_set_height(conv_height)
			# retícula 3D sobre la H + línea de trayectoria desde la pelota
			var goal_z := conv_dir * TRY_Z
			var aim_x := conv_aim * 4.2
			conv_aim_marker.global_position = Vector3(aim_x, 3.4, goal_z)
			var bp := ball.global_position + Vector3(0, 0.35, 0)
			var mid := (bp + conv_aim_marker.global_position) * 0.5
			mid.y += 1.2 + conv_height * 4.0            # arco según la altura
			conv_trail.global_position = mid
			conv_trail.look_at(conv_aim_marker.global_position, Vector3.UP)
			conv_trail.scale = Vector3(1, 1,
				bp.distance_to(conv_aim_marker.global_position))
			if Input.is_action_just_pressed("pass"):
				conv_state = ConvState.POWER
				conv_power = 0.0
				ui.conv_set_instr("ESPACIO en la zona verde")
		ConvState.POWER:
			# la barra se carga una sola vez: soltar en la zona verde = preciso
			conv_power = minf(conv_power + delta * 0.72, 1.0)
			ui.conv_set_power(conv_power)
			if Input.is_action_just_pressed("pass") or conv_power >= 1.0:
				_conv_execute()
		ConvState.WAIT_AI:
			conv_t -= delta
			if conv_t <= 0.0:
				var hdist := Vector2(conv_spot_x,
					conv_dir * TRY_Z - conv_kick_pos.z).length()
				var prob := clampf(
					(0.92 - absf(conv_spot_x) / 30.0 * 0.55) * (1.15 - hdist / 55.0),
					0.15, 0.92)
				if rng.randf() < prob:
					conv_aim = rng.randf_range(-0.14, 0.14)
					conv_power = clampf(hdist / 48.0, 0.45, 0.92) + rng.randf_range(0.0, 0.08)
				else:
					if rng.randf() < 0.6:
						conv_aim = signf(rng.randf() - 0.5) * rng.randf_range(0.45, 0.85)
						conv_power = rng.randf_range(0.5, 0.8)
					else:
						conv_aim = rng.randf_range(-0.2, 0.2)
						conv_power = rng.randf_range(0.12, 0.28)
				_conv_execute()
		ConvState.FLY:
			# paneo broadcast: cámara centrada sigue la pelota hacia los palos
			cam.set_override(Vector3(0, 7.0, -conv_dir * 20.0),
				ball.global_position + Vector3(0, 0.4, 0))
			var z := ball.global_position.z
			var posts_z := float(conv_dir) * TRY_Z
			var was := (conv_prev_z - posts_z) * conv_dir
			var now := (z - posts_z) * conv_dir
			if not conv_done_flag and was < 0.0 and now >= 0.0:
				conv_done_flag = true
				if absf(ball.global_position.x) <= 2.8 and ball.global_position.y >= 3.0:
					score[conv_team] += conv_pts
					ui.show_message("¡%s! +%d para %s" %
						["CONVERSIÓN" if conv_pts == 2 else "PENAL", conv_pts,
						_club_name(conv_team)], 2.2)
				else:
					ui.show_message("¡Falló la patada!", 2.0)
				conv_state = ConvState.DONE
				conv_t = 1.3
			elif ball.global_position.y < 0.25 and ball.linear_velocity.length() < 4.0:
				if not conv_done_flag:
					ui.show_message("¡Falló la conversión! Corta", 2.0)
				conv_state = ConvState.DONE
				conv_t = 1.0
			elif absf(z) > DEAD_Z + 6.0 or absf(ball.global_position.x) > FIELD_HALF_W + 8.0:
				if not conv_done_flag:
					ui.show_message("¡Falló la conversión! Desviada", 2.0)
				conv_state = ConvState.DONE
				conv_t = 1.0
			conv_prev_z = z
		ConvState.DONE:
			conv_t -= delta
			if conv_t <= 0.0:
				cam.clear_override()
				ui.conv_hide()
				if conv_kicker != null:
					conv_kicker.marker.visible = false
				reset_for_kickoff(1 - conv_team)


func _conv_execute() -> void:
	ui.conv_hide()
	conv_aim_marker.visible = false
	conv_trail.visible = false
	if conv_kicker != null:
		conv_kicker.kick_anim_t = 0.6
	ball.release()
	ball.global_position = conv_kick_pos + Vector3(0, 0.3, 0)
	# precisión según dónde se soltó la potencia: en la zona verde va a la
	# retícula; fuera, la pelota se desvía o queda corta
	var err := 0.0
	if conv_team == 0:
		if conv_power < CONV_SWEET_LO:
			err = -1.0 + conv_power / CONV_SWEET_LO          # corta y desviada
		elif conv_power > CONV_SWEET_HI:
			err = (conv_power - CONV_SWEET_HI) / (1.0 - CONV_SWEET_HI)
		err *= signf(rng.randf() - 0.5) * rng.randf_range(0.35, 0.9)
	var aim_x := (conv_aim + err) * 4.2
	var target := Vector3(aim_x, 4.6, conv_dir * TRY_Z)
	var dir3 := (target - ball.global_position)
	var flat := Vector3(dir3.x, 0.0, dir3.z)
	var speed := 13.0 + conv_power * 15.0
	flat = flat.normalized() * speed
	# elevación elegida con W/S: baja/rasante a globo alto
	var vy := 4.2 + conv_height * 7.5 + conv_power * 3.0
	ball.linear_velocity = Vector3(flat.x, vy, flat.z)
	_kick_sfx()
	ball.angular_velocity = Vector3(-conv_dir, 0, 0) * 12.0
	ball.release_guard = 0.4
	ball.last_touch_team = conv_team
	conv_prev_z = ball.global_position.z
	conv_state = ConvState.FLY


# ─── Eventos reglamentarios ─────────────────────────────────────────────────
func on_tackle(tackler: RugbyPlayer, carrier: RugbyPlayer) -> void:
	tackler.hit_t = 0.45
	if phase != Phase.PLAY or carrier.tackled > 0.0:
		return
	tackles_n[tackler.team] += 1
	tackler.stat_tackles += 1
	if tackler.dive_t > 0.02 and sfx_slide.stream != null:
		sfx_slide.play()
	if tackler.dive_t > 0.02 and rng.randf() < 0.1:
		tackler.tackled = 0.8
		_event_penalty(carrier.team, carrier.global_position,
			"¡PENAL para %s! Placaje alto" % _club_name(carrier.team))
		return
	tackler.tackled = 1.2
	carrier.tackled = 1.2
	if sfx_tackle.stream != null:
		sfx_tackle.play()
	# ventana de offload: el placado puede soltar la pelota a un apoyo
	offloader = carrier
	offload_t = 0.5
	pending_spot = carrier.global_position
	ruck_team = carrier.team
	ruck_dir = int(attack_dir[carrier.team])
	ui.show_message("¡PLACAJE!", 1.0)
	if rng.randf() < 0.3:
		ui.commentary("Entrada dura pero legal")
	# forcejeo con el jugador controlado involucrado
	if contest_carrier == null:
		if carrier == controlled:
			_contest_start(false, carrier)
			return
		if tackler == controlled:
			_contest_start(true, carrier)
			return
	# la IA intenta el offload si tiene apoyo cerca
	if carrier != controlled and rng.randf() < 0.45:
		on_offload(carrier)


# ─── Forcejeo post-placaje ─────────────────────────────────────────────────
func _contest_start(steal: bool, c: RugbyPlayer) -> void:
	contest_carrier = c
	contest_steal = steal
	contest_hits = 0
	contest_cursor = 0.0
	contest_sway = 1.0
	contest_speed = 1.0
	contest_zone = Vector2(0.5, 0.82)
	offloader = null              # pausa el offload/breakdown: decide el forcejeo
	offload_t = 0.0
	c.tackled = maxf(c.tackled, 6.0)
	if steal:
		# vos placaste: 3s para apretar F y forcejear, si no el rival la mueve
		contest_prompt = true
		contest_active = false
		contest_t = 3.0
		ui.flash_hint("¡F: FORCEJEAR para robar!", 2.8)
	else:
		# te placaron: machacá ESPACIO para retener la pelota
		contest_mash = true
		contest_need = 5
		contest_prompt = false
		contest_active = true
		contest_total = 5.0
		contest_t = contest_total
		ui.contest_show(false)
		ui.contest_update_mash(0, contest_need, 1.0)


func _contest_update(delta: float) -> void:
	contest_t -= delta
	if contest_prompt:
		if Input.is_action_just_pressed("tackle"):
			contest_prompt = false
			contest_mash = false       # robo: barra de timing ×3
			contest_need = 3
			contest_active = true
			contest_total = 4.5
			contest_t = contest_total
			ui.contest_show(true)
		elif contest_t <= 0.0:
			var c := contest_carrier
			_contest_clear()
			if c != null:
				_contest_ai_moves_ball(c)
		return
	if not contest_active:
		return
	if contest_mash:
		# retener: cada ESPACIO suma — hay que llegar antes de que se acabe
		ui.contest_update_mash(contest_hits, contest_need,
			maxf(0.0, contest_t / contest_total))
		if Input.is_action_just_pressed("pass"):
			contest_hits += 1
			if sfx_kick.stream != null:
				sfx_kick.pitch_scale = 0.9 + contest_hits * 0.06
				sfx_kick.play()
			if contest_hits >= contest_need:
				_contest_end(true)
		elif contest_t <= 0.0:
			_contest_end(false)
		return
	# robar: barra de timing — ESPACIO cuando la aguja está en la zona
	contest_cursor += contest_sway * delta * contest_speed * 0.7
	if contest_cursor >= 1.0:
		contest_cursor = 1.0
		contest_sway = -1.0
	elif contest_cursor <= 0.0:
		contest_cursor = 0.0
		contest_sway = 1.0
	ui.contest_update(contest_cursor, contest_zone, contest_hits)
	if Input.is_action_just_pressed("pass"):
		if contest_cursor >= contest_zone.x and contest_cursor <= contest_zone.y:
			contest_hits += 1
			contest_speed *= 1.22        # sube un poco, no se dispara
			var w := 0.30 - contest_hits * 0.05
			var zx := rng.randf_range(0.12, 0.88 - w)
			contest_zone = Vector2(zx, zx + w)
			if sfx_kick.stream != null:
				sfx_kick.pitch_scale = 1.0
				sfx_kick.play()
			if contest_hits >= contest_need:
				_contest_end(true)
		else:
			_contest_end(false)
	elif contest_t <= 0.0:
		_contest_end(false)


func _contest_end(win: bool) -> void:
	var c := contest_carrier
	var steal := contest_steal
	_contest_clear()
	if c == null:
		return
	c.tackled = minf(c.tackled, 1.4)
	if steal:
		if win:
			_contest_give_ball(c, 0, "¡ROBO EN EL CONTACTO!")
		else:
			_contest_ai_moves_ball(c)
	else:
		if win:
			# retuviste: sale jugada limpia a un apoyo
			var support := _nearest(c.team, c.global_position, c, 14.0)
			if support != null:
				ball.throw_to(support, c)
				ui.flash_hint("¡RETUVISTE! Jugada limpia", 1.8)
				crowd_boost = 3.5        # la tribuna responde
			else:
				_begin_breakdown(c)
		else:
			_contest_give_ball(c, 1, "¡TE LA ROBARON!")


func _contest_give_ball(c: RugbyPlayer, team: int, msg: String) -> void:
	var n := _nearest(team, pending_spot, null, 16.0)
	if n != null:
		ball.set_carrier(n)
		ui.show_message(msg, 1.8)
		if sfx_slide.stream != null:
			sfx_slide.play()
	else:
		_begin_breakdown(c)


# no forcejeaste o perdiste el robo: el rival mueve la pelota a un apoyo
func _contest_ai_moves_ball(c: RugbyPlayer) -> void:
	offloader = c
	offload_t = 0.4
	on_offload(c)
	if offloader != null:
		pass   # sin apoyo: el timer del offload dispara el ruck normal


func _contest_clear() -> void:
	contest_carrier = null
	contest_steal = false
	contest_mash = false
	contest_prompt = false
	contest_active = false
	contest_t = 0.0
	contest_hits = 0
	sfx_kick.pitch_scale = 1.0
	ui.contest_hide()


# se acabó la ventana: la pelota va al piso y se forma el ruck
func _begin_breakdown(c: RugbyPlayer) -> void:
	var support := _nearest(c.team, c.global_position, c, 14.0)
	if support != null and rng.randf() < 0.85:
		pending_team = c.team
	else:
		pending_team = 1 - c.team
	phase = Phase.BREAKDOWN
	phase_t = 2.6 if c.team == 0 else 1.15
	# rearmado ordenado: cada jugador tiene su posición del ruck
	var d := float(ruck_dir)
	var spot := pending_spot
	var pdir := -signf(spot.x) if absf(spot.x) > 6.0 else 1.0
	for p in players:
		if p.tackled > 0.0:
			continue
		if p.team == ruck_team:
			if p.index < 8:
				var pod := p.index / 3
				p.hold_pos = Vector3(clampf(
					spot.x + pdir * (4.5 + pod * 5.5) +
					(p.index % 3 - 1.0) * 1.9, -30.0, 30.0),
					0.0, spot.z - d * 3.0)
			elif p.index == 8:
				p.hold_pos = spot - Vector3(0, 0, d * 2.0)
			else:
				var slot := p.index - 9
				var bdir := pdir if slot < 3 else -pdir
				p.hold_pos = Vector3(clampf(
					spot.x + bdir * (5.0 + (slot % 3) * 5.5),
					-30.0, 30.0), 0.0, spot.z - d * (6.0 - slot * 0.4))
		else:
			var lane := -28.0 + p.index * 4.0
			p.hold_pos = Vector3(clampf(lane + spot.x * 0.3, -30.0, 30.0),
				0.0, spot.z + d * 3.5)   # línea del lado de SU ingoal
	if c.team == 0:
		ui.flash_hint(
			"RUCK — Q abrir izquierda · E abrir derecha · Espacio pick and go",
			2.6)


# offload: el placado tira la pelota hacia atrás antes de ir al piso
func on_offload(c: RugbyPlayer) -> void:
	if offloader != c or offload_t <= 0.0:
		return
	var target := find_pass_target(c, true)
	if target == null:
		return
	offloader = null
	offload_t = 0.0
	ball.throw_to(target, c)
	ui.flash_hint("¡OFFLOAD!")


func _confetti(pos: Vector3, club_col: Color) -> void:
	if confetti == null:
		confetti = GPUParticles3D.new()
		confetti.amount = 280
		confetti.lifetime = 2.6
		confetti.one_shot = true
		confetti.explosiveness = 0.85
		confetti.visibility_aabb = AABB(Vector3(-40, -15, -40),
			Vector3(80, 50, 80))
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 2.0
		pm.direction = Vector3(0.0, 1.0, 0.0)
		pm.spread = 55.0
		pm.initial_velocity_min = 9.0
		pm.initial_velocity_max = 15.0
		pm.gravity = Vector3(0.0, -9.0, 0.0)
		pm.damping_min = 1.2
		pm.damping_max = 2.6
		confetti.process_material = pm
		var quad := QuadMesh.new()
		quad.size = Vector2(0.16, 0.16)
		var cm := StandardMaterial3D.new()
		cm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		quad.material = cm
		confetti.draw_pass_1 = quad
		confetti.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(confetti)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.84, 0.2))
	grad.set_color(1, club_col)
	grad.add_point(0.5, Color(0.95, 0.95, 0.95))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	(confetti.process_material as ParticleProcessMaterial).color_ramp = gt
	confetti.global_position = pos + Vector3(0.0, 2.0, 0.0)
	confetti.restart()


func _build_stats_text(poss_pct: String) -> String:
	var t := "  FINAL DEL PARTIDO\n\n"
	t += "  %s  %d — %d  %s\n" % [_club_name(0), score[0], score[1], _club_name(1)]
	t += "  Posesión %s  ·  Tries %d-%d  ·  Placajes %d-%d\n\n" % [
		poss_pct.replace("Posesión ", "").replace("· ", ""),
		tries_n[0], tries_n[1], tackles_n[0], tackles_n[1]]
	# goleadores
	var scorers: Array = []
	for p in players:
		if p.stat_tries > 0:
			scorers.append(p)
	scorers.sort_custom(func(a, b): return a.stat_tries > b.stat_tries)
	if scorers.size() > 0:
		t += "  TRIES\n"
		for p in scorers.slice(0, 5):
			t += "  #%d %s %s — %d try%s\n" % [p.index + 1, p.pname,
				POS_NAMES[p.index], p.stat_tries,
				"s" if p.stat_tries > 1 else ""]
		t += "\n"
	# placadores
	var tacklers := players.duplicate()
	tacklers.sort_custom(func(a, b): return a.stat_tackles > b.stat_tackles)
	if tacklers.size() > 0 and tacklers[0].stat_tackles > 0:
		t += "  PLACAJES\n"
		for p in tacklers.slice(0, 3):
			t += "  #%d %s %s — %d\n" % [p.index + 1, p.pname,
				POS_NAMES[p.index], p.stat_tackles]
		t += "\n"
	# metros corridos
	var runners := players.duplicate()
	runners.sort_custom(func(a, b): return a.stat_metros > b.stat_metros)
	if runners.size() > 0 and runners[0].stat_metros > 20.0:
		t += "  METROS CON PELOTA\n"
		for p in runners.slice(0, 3):
			t += "  #%d %s %s — %dm\n" % [p.index + 1, p.pname,
				POS_NAMES[p.index], int(p.stat_metros)]
	t += "\n  R revancha · M menú"
	return t


func _resolve_breakdown() -> void:
	# ruck por numeros: mas defensores que apoyos = robo probable
	var att := 0
	var def := 0
	for p in players:
		if p.tackled > 0.0 or p.sin_bin_t > 0.0:
			continue
		if p.global_position.distance_to(pending_spot) < 5.0:
			if p.team == ruck_team:
				att += 1
			else:
				def += 1
	var extra_steal := clampf(float(def - att) * 0.12, 0.0, 0.3)
	# el portador quedo aislado: "no solto" puede ser penal para la defensa
	if att <= 1 and rng.randf() < 0.09:
		_event_penalty(1 - ruck_team, pending_spot,
			"¡PENAL para %s! No soltó la pelota" % _club_name(1 - ruck_team))
		jackal_pressed = false
		return
	# offside: defensor parado delante de la última línea
	for p in players:
		if p.team == ruck_team or p.tackled > 0.0 or p.sin_bin_t > 0.0:
			continue
		if (p.global_position.z - pending_spot.z) * float(ruck_dir) > 3.0:
			if rng.randf() < 0.2:
				_event_penalty(ruck_team, pending_spot,
					"¡PENAL! Offside de %s" % _club_name(1 - ruck_team))
				jackal_pressed = false
				return
			break
	# jackal: un defensor sobre la pelota puede robarla
	var jk := _nearest(1 - ruck_team, pending_spot, null, 3.2)
	if jk != null:
		var steal := 0.16 + extra_steal
		if jackal_pressed and controlled == jk:
			steal += 0.3
		if rng.randf() < steal:
			ball.set_carrier(jk)
			phase = Phase.PLAY
			jackal_pressed = false
			ui.flash_hint("¡ROBO EN EL RUCK de %s!" % _club_name(1 - ruck_team))
			ui.commentary("¡El jackal mete las manos y se queda con todo!")
			return
	jackal_pressed = false
	# penal de ruck para el equipo atacante (10%)
	if rng.randf() < 0.1:
		var adv := pending_spot + Vector3(0, 0, float(ruck_dir) * 10.0)
		adv.z = clampf(adv.z, -TRY_Z + 6.0, TRY_Z - 6.0)
		_event_penalty(ruck_team, adv,
			"¡PENAL para %s! Infracción en el ruck" % _club_name(ruck_team))
		return
	# pick and go: un forward cerca del ruck puede picar y avanzar
	if pending_team == ruck_team and rng.randf() < 0.4:
		var f := _nearest_forward(pending_team, pending_spot, 4.0)
		if f != null:
			ball.set_carrier(f)
			f.surge_t = 0.5
			ui.flash_hint("¡Pick and go!")
			phase = Phase.PLAY
			jackal_pressed = false
			return
	# el medioscrum (9) tiene prioridad si está cerca
	var nine := players[8 + ruck_team * TEAM_SIZE]
	var p: RugbyPlayer = null
	if nine.tackled <= 0.0 and pending_team == ruck_team \
			and nine.global_position.distance_to(pending_spot) < 18.0:
		p = nine
	else:
		p = _nearest(pending_team, pending_spot, null, 999.0)
	if p != null:
		ball.set_carrier(p)
	phase = Phase.PLAY
	settle_t = 0.45


# salida del scrum dirigida: Q/E por un lado del 9, Espacio pick del 8
func _scrum_play(side: int) -> void:
	if phase != Phase.SCRUM or pending_team != 0:
		return
	if rng.randf() < 0.06:
		# te roban la introducción igual
		var tn := players[8 + TEAM_SIZE]
		ball.set_carrier(tn)
		ui.show_message("¡TIGHT HEAD! Te robaron el scrum", 2.0)
		phase = Phase.PLAY
		return
	if side == 0:
		# pick del octavo: agarra del pie del scrum y carga
		var eight := players[7]
		ball.set_carrier(eight)
		eight.surge_t = 0.7
		ui.flash_hint("¡Pick del 8!")
	else:
		var nine := players[8]
		ball.set_carrier(nine)
		var target := find_pass_target_side(nine, side)
		if target != null and target != nine:
			nine.pass_anim_t = 0.3
			ball.throw_to(target, nine)
	phase = Phase.PLAY
	settle_t = 0.4


# tiro de lineout dirigido: 0 corto al 9 · 1 largo al 10 · 2 maul
func _lineout_play(opt: int) -> void:
	if phase != Phase.LINEOUT or pending_team != 0:
		return
	var hooker := players[1]
	ball.freeze = false
	pending_maul_team = -1
	if opt == 1:
		var ten := players[9]
		ball.throw_to(ten, hooker)
		ball.pass_from = null
		ui.flash_hint("¡Largo al 10!")
	else:
		var jumper: RugbyPlayer = players[4]
		if jumper.tackled > 0.0:
			jumper = _nearest(0, pending_spot, null, 999.0)
		if jumper != null:
			ball.throw_to(jumper, hooker)
			ball.pass_from = null
		if opt == 0:
			var nine := players[8]
			if jumper != null and nine.tackled <= 0.0:
				ball.throw_to(nine, jumper)
				ball.pass_from = null
			ui.flash_hint("¡Corto al 9!")
		else:
			pending_maul_team = 0
			ui.flash_hint("¡Maul!")
	phase = Phase.PLAY


# ruck dirigido por el jugador: el 9 abre la pelota donde elegís
func _ruck_play(side: int) -> void:
	if phase != Phase.BREAKDOWN or ruck_team != 0:
		return
	var server: RugbyPlayer = players[8]
	if server.tackled > 0.0 or server.sin_bin_t > 0.0:
		server = _nearest(0, pending_spot, null, 999.0)
	if server == null:
		_resolve_breakdown()
		return
	ball.set_carrier(server)
	if side == 0:
		var f := _nearest_forward(0, pending_spot, 6.0)
		if f != null and f != server:
			ball.set_carrier(f)
			f.surge_t = 0.5
			ui.flash_hint("¡Pick and go!")
	else:
		var target := find_pass_target_side(server, side)
		if target == null:
			target = find_pass_target(server, true)
		if target != null and target != server:
			server.pass_anim_t = 0.3
			ball.throw_to(target, server)
	phase = Phase.PLAY
	settle_t = 0.5
	jackal_pressed = false


# marca: pelota de patada rival atrapada dentro de tus 22
func on_mark(catcher: RugbyPlayer) -> void:
	_whistle()
	ui.show_message("¡MARCA! %s juega rápido" % _club_name(catcher.team), 1.6)
	# los rivales tienen que retroceder: los empujamos hacia su línea
	var back := float(attack_dir[catcher.team]) * -8.0
	for p in players:
		if p.team == catcher.team:
			continue
		if p.global_position.distance_to(catcher.global_position) < 12.0:
			p.global_position.z += back
			p.global_position.z = clampf(p.global_position.z,
				-DEAD_Z + 2.0, DEAD_Z - 2.0)


func on_forward_pass(thrower: RugbyPlayer) -> void:
	_start_advantage(1 - thrower.team, thrower.global_position,
		"¡Pase adelantado! VENTAJA para %s" % _club_name(1 - thrower.team))


func on_knock_on(player: RugbyPlayer) -> void:
	_start_advantage(1 - player.team, player.global_position,
		"¡Knock-on! VENTAJA para %s" % _club_name(1 - player.team))


# el árbitro juega la ventaja: si el otro equipo no aprovecha, hay scrum
func _start_advantage(team: int, spot: Vector3, msg: String) -> void:
	if phase != Phase.PLAY:
		return
	adv_team = team
	adv_spot = spot
	adv_t = 5.0
	adv_hold = 0.0
	ui.show_message(msg, 1.8)
	_whistle()


func _event_scrum(feed_team: int, spot: Vector3, msg: String) -> void:
	if phase != Phase.PLAY and phase != Phase.BREAKDOWN:
		return
	ui.show_message(msg, 2.2)
	_whistle()
	pending_team = feed_team
	pending_spot = Vector3(clampf(spot.x, -FIELD_HALF_W + 6.0, FIELD_HALF_W - 6.0),
		0.0, clampf(spot.z, -TRY_Z + 7.0, TRY_Z - 7.0))
	if feed_team == 0:
		ui.flash_hint("SCRUM — Q/E salida del 9 · Espacio pick del 8", 2.6)
	ball.release()
	ball.freeze = true
	ball.global_position = pending_spot + Vector3(0, 0.25, 0)
	for p in players:
		p.hold_pos = p.global_position
	phase = Phase.SCRUM
	phase_t = 2.4


func _resolve_scrum() -> void:
	if rng.randf() < 0.08:
		# tight head: el pack rival roba la introducción
		var tn := players[8 + (1 - pending_team) * TEAM_SIZE]
		ball.set_carrier(tn)
		ui.show_message("¡TIGHT HEAD! Robo del scrum de %s"
			% _club_name(1 - pending_team), 2.0)
		phase = Phase.PLAY
		return
	var nine := players[8 + pending_team * TEAM_SIZE]
	var p: RugbyPlayer = nine if nine.tackled <= 0.0 else _nearest(pending_team, pending_spot, null, 999.0)
	if p != null:
		ball.set_carrier(p)
	ui.flash_hint("¡Sale el scrum!")
	phase = Phase.PLAY


func _event_lineout(throw_team: int, mark_z: float, side: float, msg: String) -> void:
	ui.show_message(msg, 2.0)
	_whistle()
	pending_team = throw_team
	lineout_mark = clampf(mark_z, -44.0, 44.0)
	lineout_side = signf(side) if side != 0.0 else 1.0
	pending_spot = Vector3(lineout_side * (FIELD_HALF_W - 5.0), 0.0, lineout_mark)
	var hooker := players[1 + throw_team * TEAM_SIZE]
	ball.release()
	ball.freeze = true
	ball.global_position = Vector3(lineout_side * (FIELD_HALF_W + 1.0), 1.0, lineout_mark)
	for p in players:
		p.hold_pos = p.global_position
	hooker.hold_pos = ball.global_position
	phase = Phase.LINEOUT
	phase_t = 1.9
	if throw_team == 0:
		ui.flash_hint("LINEOUT — Q corto al 9 · E largo al 10 · Espacio maul", 2.6)


func _resolve_lineout() -> void:
	# 82% retiene el equipo que tira, 18% robo rival
	var catch_team := pending_team if rng.randf() < 0.82 else 1 - pending_team
	var catcher := players[4 + catch_team * TEAM_SIZE]
	if catcher.tackled > 0.0:
		catcher = _nearest(catch_team, pending_spot, null, 999.0)
	var hooker := players[1 + pending_team * TEAM_SIZE]
	ball.freeze = false
	if catcher != null:
		ball.throw_to(catcher, hooker)
		ball.pass_from = null   # sin knock-on en el lineout
	else:
		ball.set_carrier(_nearest(catch_team, pending_spot, null, 999.0))
	# opciones: maul 55% / tirar largo al 10 20% / sale el 9 25%
	pending_maul_team = -1
	var roll := rng.randf()
	if roll < 0.55:
		pending_maul_team = catch_team
	elif roll < 0.75:
		var ten := players[9 + catch_team * TEAM_SIZE]
		if ten.tackled <= 0.0:
			ball.throw_to(ten, catcher)
			ball.pass_from = null
			ui.flash_hint("¡Lineout largo al 10!")
	phase = Phase.PLAY


func _start_maul(team: int) -> void:
	maul_team = team
	maul_dir = float(attack_dir[team])
	phase = Phase.MAUL
	phase_t = 2.0
	ui.flash_hint("¡MAUL! Empuja el pack")
	ui.commentary("El pack empuja como una sola unidad")


func _update_maul(delta: float) -> void:
	phase_t -= delta
	var c := ball.carrier
	if c == null or c.team != maul_team:
		phase = Phase.PLAY
		return
	# el maul avanza ~2.4 m/s empujado por los forwards
	c.global_position.z += maul_dir * 2.4 * delta
	c.global_position.x = lerpf(c.global_position.x, 0.0, delta * 0.3)
	c.global_position.x = clampf(c.global_position.x,
		-FIELD_HALF_W + 1.0, FIELD_HALF_W - 1.0)
	# ¿el drive llegó al in-goal? try de maul
	if c.global_position.z * maul_dir > TRY_Z:
		_on_try(maul_team)
		return
	if phase_t <= 0.0:
		if rng.randf() < 0.15:
			# colapso ilegal: scrum para la defensa
			_event_scrum(1 - maul_team, c.global_position,
				"¡Maul colapsado! Scrum para %s" % _club_name(1 - maul_team))
			return
		# sale el 9 con la pelota
		var nine := players[8 + maul_team * TEAM_SIZE]
		if nine.tackled <= 0.0 and nine.sin_bin_t <= 0.0:
			ball.set_carrier(nine)
		phase = Phase.PLAY


func _event_penalty(team: int, spot: Vector3, msg: String) -> void:
	ui.show_message(msg, 2.2)
	if rng.randf() < 0.4:
		ui.commentary("El árbitro no perdona la infracción")
	_whistle()
	pending_team = team
	pending_spot = spot
	# acumulación de penales → tarjeta amarilla
	var offender := 1 - team
	pen_count[offender] += 1
	total_pens[offender] += 1
	if pen_count[offender] >= 2:
		var card := _nearest(offender, spot, null, 999.0)
		if card != null:
			var is_red: bool = total_pens[offender] >= 4
			card.sin_bin_t = 9999.0 if is_red else 45.0
			card.tackled = 0.0
			card.global_position = Vector3(
				signf(spot.x + 1.0) * (FIELD_HALF_W + 6.0), 0.0, spot.z)
			if not is_red:
				pen_count[offender] = 0
			ui.show_message("¡TARJETA ROJA! %s se queda con 14 todo el partido"
				% _club_name(offender), 3.5) if is_red \
				else ui.show_message("¡TARJETA AMARILLA! %s juega con 14"
				% _club_name(offender), 3.0)
	ball.release()
	ball.freeze = true
	ball.global_position = spot + Vector3(0, 1.0, 0)
	phase = Phase.PENALTY
	phase_t = 1.1
	if team == 0:
		phase_t = 7.0   # el jugador decide cómo jugarlo
		if _pen_in_range():
			ui.flash_hint("ESPACIO: tap rápido · K: a los palos (+3)")


# distancia razonable para patear a los palos desde el penal
func _pen_in_range() -> bool:
	var d := float(attack_dir[pending_team])
	var dist := TRY_Z - pending_spot.z * d
	return dist < 44.0 and absf(pending_spot.x) < 28.0


func _pen_touch_kick() -> void:
	# patada a la banda → lineout propio donde cae
	var side := signf(pending_spot.x)
	if side == 0.0:
		side = 1.0
	ball.global_position = pending_spot + Vector3(0.0, 1.1, 0.0)
	ball.release()
	ball.was_kicked = true
	ball.last_touch_team = pending_team
	ball.pass_from = null
	var dir := Vector3(side, 0.0, float(attack_dir[pending_team]) * 0.7).normalized()
	ball.linear_velocity = dir * 22.0 + Vector3(0.0, 7.5, 0.0)
	ball.angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 14.0
	_kick_sfx()
	ui.show_message("¡Patada al touch! Lineout para %s"
		% _club_name(pending_team), 2.0)
	phase = Phase.PLAY


func _resolve_penalty() -> void:
	# la IA decide a los palos si está en rango
	if pending_team == 1:
		if _pen_in_range() and rng.randf() < 0.45:
			_setup_penalty_goal()
			return
		# la IA patea al touch cuando está lejos de los palos
		if rng.randf() < 0.4:
			_pen_touch_kick()
			return
	var p := _nearest(pending_team, pending_spot, null, 999.0)
	if p != null:
		ball.set_carrier(p)
		p.hold_pos = pending_spot
	ui.flash_hint("¡Penal jugado rápido!")
	phase = Phase.PLAY


# puntos reales URT: 4 victoria, 2 empate, bonus por 4+ tries y por perder <8
func _record_result(h: int, a: int, sh: int, sa: int, th: int, ta: int) -> void:
	var ht: Dictionary = tour_table[h]
	var at: Dictionary = tour_table[a]
	ht.played += 1
	at.played += 1
	ht.pf += sh
	ht.pa += sa
	at.pf += sa
	at.pa += sh
	if sh > sa:
		ht.won += 1
		ht.pts += 4
		at.lost += 1
	elif sh < sa:
		at.won += 1
		at.pts += 4
		ht.lost += 1
	else:
		ht.drawn += 1
		at.drawn += 1
		ht.pts += 2
		at.pts += 2
	if th >= 4:
		ht.pts += 1
		ht.bonus += 1
	if ta >= 4:
		at.pts += 1
		at.bonus += 1
	if sh > sa and sh - sa < 8:
		at.pts += 1
		at.bonus += 1
	elif sa > sh and sa - sh < 8:
		ht.pts += 1
		ht.bonus += 1


# simula los otros 5 partidos de la fecha según el rating de cada club
func _sim_fecha() -> void:
	var others: Array[int] = []
	for i in RugbyTeams.CLUBS.size():
		if i != home_idx and i != away_idx:
			others.append(i)
	others.shuffle()
	for i in range(0, others.size() - 1, 2):
		var h := others[i]
		var a := others[i + 1]
		var rh: float = RugbyTeams.CLUBS[h]["rating"]
		var ra: float = RugbyTeams.CLUBS[a]["rating"]
		var edge := (rh - ra) * 12.0
		var sh := maxi(0, int(17 + edge + rng.randi_range(-11, 11)))
		var sa := maxi(0, int(17 - edge + rng.randi_range(-11, 11)))
		_record_result(h, a, sh, sa, int(sh / 7.0), int(sa / 7.0))
		sim_log.append("%s %d-%d %s" % [
			RugbyTeams.CLUBS[h]["abbr"], sh, sa,
			RugbyTeams.CLUBS[a]["abbr"]])


func _table_order() -> Array:
	var idx: Array = range(tour_table.size())
	idx.sort_custom(func(a, b):
		var ta: Dictionary = tour_table[a]
		var tb: Dictionary = tour_table[b]
		if ta.pts != tb.pts:
			return ta.pts > tb.pts
		return (ta.pf - ta.pa) > (tb.pf - tb.pa))
	return idx


func _table_text() -> String:
	var t := "  TABLA URT — FECHA %d\n" % (tour_pos + 1)
	t += "   #  Club                PJ PG PE PP   PF   PA  Pts\n"
	var order := _table_order()
	for i in order.size():
		var c: int = order[i]
		var d: Dictionary = tour_table[c]
		var mark := "▶" if c == home_idx else " "
		t += "%s %2d  %-19s %2d %2d %2d %2d %4d %4d %4d\n" % [
			mark, i + 1, RugbyTeams.CLUBS[c]["abbr"], d.played, d.won,
			d.drawn, d.lost, d.pf, d.pa, d.pts]
	return t


func _tour_next() -> void:
	tour_pos += 1
	if tour_pos >= tour_fixture.size():
		var champ: int = _table_order()[0]
		var res := "¡TORNEO TERMINADO!\n\nCAMPEÓN: %s\n\n%s\nTu posición: #%d" % [
			RugbyTeams.CLUBS[champ]["name"], _table_text(),
			_table_order().find(home_idx) + 1]
		return_to_menu()
		menu.flash_result(res)
		return
	start_match(home_idx, tour_fixture[tour_pos], "tournament")


func _event_dropout(team: int, msg: String) -> void:
	ui.show_message(msg, 2.2)
	_whistle()
	drop_team = team
	pending_team = team
	ball.release()
	ball.freeze = true
	var d := float(attack_dir[team])
	ball.global_position = Vector3(0.0, 0.9, -d * 28.0)
	var kicker := players[9 + team * TEAM_SIZE]
	kicker.global_position = ball.global_position + Vector3(0, 0, d * 1.5)
	kicker.hold_pos = kicker.global_position
	phase = Phase.DROPOUT
	phase_t = 1.2


func _resolve_dropout() -> void:
	var d := float(attack_dir[drop_team])
	ball.release()
	var target := Vector3(rng.randf_range(-14.0, 14.0), 0.0, d * rng.randf_range(15.0, 45.0))
	var diff := target - ball.global_position
	var t := clampf(Vector2(diff.x, diff.z).length() / 20.0, 1.4, 2.4)
	ball.linear_velocity = Vector3(diff.x / t, (diff.y + 4.9 * t * t) / t, diff.z / t)
	ball.angular_velocity = Vector3(d, 0, 0) * 10.0
	ball.release_guard = 0.35
	ball.last_touch_team = drop_team
	_kick_sfx()
	phase = Phase.PLAY


# ─── Formaciones para scrum / lineout ───────────────────────────────────────
func get_formation_pos(p: RugbyPlayer) -> Vector3:
	if phase == Phase.SCRUM:
		return _scrum_pos(p)
	if phase == Phase.LINEOUT:
		return _lineout_pos(p)
	return p.global_position


func _scrum_pos(p: RugbyPlayer) -> Vector3:
	var kd := float(attack_dir[pending_team])
	var side := 1.0 if p.team == pending_team else -1.0
	if p.is_forward():
		# pack: 3 front row, 2 segunda línea, 2 flankers, 1 octavo
		var slots := [Vector2(0, 0), Vector2(-1.1, 0), Vector2(1.1, 0),
			Vector2(-0.6, 1.1), Vector2(0.6, 1.1),
			Vector2(-2.0, 1.5), Vector2(2.0, 1.5), Vector2(0, 2.4)]
		var s: Vector2 = slots[p.index]
		return pending_spot + Vector3(s.x, 0.0, -kd * side * (1.5 + s.y))
	# backs a 5m detrás de su pack
	var lane := (p.index - 11.0) * 2.6
	return pending_spot + Vector3(lane, 0.0, -kd * side * 7.5)


func _lineout_pos(p: RugbyPlayer) -> Vector3:
	var sx := lineout_side
	var own_dir := float(attack_dir[p.team])
	if p.is_forward():
		if p.team == pending_team and p.index == 1:
			# hooker tira desde el touch
			return Vector3(sx * (FIELD_HALF_W + 1.0), 0.0, lineout_mark)
		var slot := p.index
		if p.team == pending_team and p.index > 1:
			slot -= 1
		var row_z := 0.55 if p.team == pending_team else -0.55
		var x := sx * (FIELD_HALF_W - 5.0) - sx * slot * 1.05
		return Vector3(x, 0.0, lineout_mark + row_z)
	# backs: detrás del lineout hacia su propio in-goal
	var lane := (p.index - 11.0) * 2.8
	return Vector3(sx * (FIELD_HALF_W - 8.0) - sx * 9.0 + lane * 0.3, 0.0,
		lineout_mark - own_dir * 4.0 + lane * 0.6)


# ─── Utilidades ─────────────────────────────────────────────────────────────
func _nearest_forward(team: int, pos: Vector3, maxd: float) -> RugbyPlayer:
	var best: RugbyPlayer = null
	var bd := maxd
	for p in players:
		if p.team != team or not p.is_forward() or p.tackled > 0.0 \
				or p.sin_bin_t > 0.0:
			continue
		var d := p.global_position.distance_to(pos)
		if d < bd:
			bd = d
			best = p
	return best


func _nearest(team: int, pos: Vector3, exclude: RugbyPlayer, maxd: float) -> RugbyPlayer:
	var best: RugbyPlayer = null
	var bd := maxd
	for p in players:
		if p.team != team or p == exclude or p.tackled > 0.0 or p.sin_bin_t > 0.0:
			continue
		var d := p.global_position.distance_to(pos)
		if d < bd:
			bd = d
			best = p
	return best


func find_pass_target(carrier: RugbyPlayer, behind_only := true) -> RugbyPlayer:
	var d := float(attack_dir[carrier.team])
	var best: RugbyPlayer = null
	var bd := -999.0
	for p in players:
		if p.team != carrier.team or p == carrier or p.tackled > 0.0 \
				or p.sin_bin_t > 0.0:
			continue
		var fwd := (p.global_position.z - carrier.global_position.z) * d
		if behind_only and fwd > 0.4:
			continue
		var dist := carrier.global_position.distance_to(p.global_position)
		if dist < 2.0 or dist > 16.0:
			continue
		var sc := -absf(dist - 8.0)              # distancia ideal ~8m
		sc -= absf(fwd) * 0.6                    # castiga los muy atrás
		sc += absf(rel_x(p, carrier)) * 0.28     # premia el ancho
		if sc > bd:
			bd = sc
			best = p
	return best


func rel_x(p: RugbyPlayer, c: RugbyPlayer) -> float:
	return p.global_position.x - c.global_position.x


# busca receptor en un lado concreto del portador
# side: -1 = izquierda, +1 = derecha (relativo a la dirección de ataque)
func find_pass_target_side(carrier: RugbyPlayer, side: int) -> RugbyPlayer:
	var d := float(attack_dir[carrier.team])
	var best: RugbyPlayer = null
	var bs := -999.0
	for p in players:
		if p.team != carrier.team or p == carrier or p.tackled > 0.0 \
				or p.sin_bin_t > 0.0:
			continue
		var rel := p.global_position - carrier.global_position
		var fwd := rel.z * d
		if fwd > 0.4:
			continue                         # sería pase adelantado
		var dist := rel.length()
		if dist < 1.5 or dist > 18.0:
			continue
		# lat > 0 → está a la izquierda del ataque; side=-1 lo quiere
		var lat := rel.x * d * float(-side)
		if lat < -1.2:
			continue                         # está del lado contrario
		var sc := lat * 2.5 - dist * 0.25
		if sc > bs:
			bs = sc
			best = p
	return best


func _select_controlled() -> void:
	sel_cd = maxf(0.0, sel_cd - get_process_delta_time())
	var want: RugbyPlayer = controlled
	# siempre: quien lleva la pelota es el controlado
	if ball.carrier != null and ball.carrier.team == 0:
		want = ball.carrier
	elif opt_selmode == 0:
		# automática: el más cercano a la pelota, con histéresis fuerte y
		# sin cambiar mientras la pelota viaja en el aire (pase/patada)
		if (phase == Phase.PLAY or phase == Phase.KICKOFF) and sel_cd <= 0.0:
			if ball.pass_from == null or ball.global_position.y < 1.5:
				var n := _nearest(0, ball.global_position, null, 999.0)
				if n != null:
					if controlled == null or controlled.team != 0 \
							or controlled.tackled > 0.0 or controlled.sin_bin_t > 0.0:
						want = n
					else:
						var dn := n.global_position.distance_to(ball.global_position)
						var dc := controlled.global_position.distance_to(ball.global_position)
						if dn < dc * 0.6:
							want = n
	elif opt_selmode == 1:
		# mixta: auto solo cuando el controlado no puede jugar; el click
		# manual siempre está disponible
		if controlled == null or controlled.tackled > 0.0 \
				or controlled.sin_bin_t > 0.0:
			want = _nearest(0, ball.global_position, null, 999.0)
	# manual: solo cambia por click o por llevar la pelota
	if want != null and want != controlled:
		controlled = want
		sel_cd = 0.5


# selección con el cursor como puntero: click sobre un jugador lo controla
func _click_select(mp: Vector2) -> void:
	if opt_selmode == 0:
		return
	if phase != Phase.PLAY and phase != Phase.KICKOFF:
		return
	var from := cam.project_ray_origin(mp)
	var d := cam.project_ray_normal(mp)
	if d.y >= -0.01:
		return
	var hit := from + d * (-from.y / d.y)   # punto del click en el piso
	var best: RugbyPlayer = null
	var bd := 4.5
	for p in players:
		if p.team != 0 or p.tackled > 0.0 or p.sin_bin_t > 0.0:
			continue
		var dd := Vector2(p.global_position.x - hit.x,
			p.global_position.z - hit.z).length()
		if dd < bd:
			bd = dd
			best = p
	if best != null and best != controlled:
		controlled = best
		sel_cd = 0.5
		ui.flash_hint("Controlando: #%d %s" % [best.index + 1, best.pname])


func cam_move_dir(iv: Vector2) -> Vector3:
	var b := cam.global_transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var fwd := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	return (right * iv.x - fwd * iv.y).normalized()


func _refresh_ui() -> void:
	ui.set_score(_club_name(0), score[0], score[1], _club_name(1))
	var m := int(clock) / 60
	var s := int(clock) % 60
	ui.set_clock("%dT  %02d:%02d" % [half, m, s])
