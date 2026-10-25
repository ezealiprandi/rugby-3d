extends Node3D
class_name RugbyGame

# ─── Constantes del juego ───────────────────────────────────────────────────
const FIELD_HALF_W := 35.0        # semiancho (touchlines en |x| = 35)
const TRY_Z := 50.0               # líneas de try en |z| = 50
const DEAD_Z := 60.0              # línea de pelota muerta
const TEAM_SIZE := 15
const HALF_LEN := 180.0           # segundos por tiempo
const TACKLE_RANGE := 1.35
const PICKUP_RANGE := 1.4

enum Phase { MENU, KICKOFF, PLAY, BREAKDOWN, SCRUM, LINEOUT, CONVERSION,
	DROPOUT, PENALTY, SCORE, BETWEEN, END }

var players: Array[RugbyPlayer] = []
var ball: RugbyBall
var controlled: RugbyPlayer = null
var cam: RugbyCam
var ui: RugbyUI
var menu: RugbyMenu
var referee: RugbyReferee

# modos de juego: "friendly" | "tournament" | "practice"
var mode := "friendly"
var tour_fixture: Array[int] = []
var tour_pos := 0
var tour_wins := 0
var tour_losses := 0

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
var conv_pts := 2                     # 2 conversión · 3 penal a los palos

# drop goal en juego abierto
var drop_goal_team := -1
var drop_prev_z := 0.0

# disciplina
var pen_count := [0, 0]
var celebrating: RugbyPlayer = null

# audio
var sfx_whistle: AudioStreamPlayer
var sfx_crowd: AudioStreamPlayer
var sfx_cheer: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_register_input()
	RugbyField.build(self)
	_spawn_ball()
	ball.global_position = Vector3(0.0, 0.6, 0.0)
	cam = RugbyCam.new()
	cam.game = self
	add_child(cam)
	ui = RugbyUI.new()
	add_child(ui)
	menu = RugbyMenu.new()
	menu.game = self
	add_child(menu)
	sfx_whistle = _mk_audio("res://assets/whistle.wav", -6.0)
	sfx_crowd = _mk_audio("res://assets/crowd.wav", -16.0)
	sfx_cheer = _mk_audio("res://assets/cheer.wav", -4.0)
	ui.set_info("WASD mover · Shift sprint · Espacio pasar · K patada · Esc pausa")
	ui.visible = false
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


func _mk_audio(path: String, db: float) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new()
	a.volume_db = db
	if ResourceLoader.exists(path):
		a.stream = load(path)
	add_child(a)
	return a


func _whistle() -> void:
	if sfx_whistle.stream != null:
		sfx_whistle.play()


# ─── Setup ──────────────────────────────────────────────────────────────────
func _spawn_ball() -> void:
	ball = RugbyBall.new()
	ball.game = self
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
			p.rating = club["rating"]
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
			add_child(p)
			players.append(p)
	# árbitro + jueces de touch
	if referee == null:
		referee = RugbyReferee.new()
		referee.game = self
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
	drop_goal_team = -1
	celebrating = null
	first_kicker = 1   # el equipo del jugador recibe el saque inicial
	if sfx_crowd.stream != null and not sfx_crowd.playing:
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
		away = tour_fixture[tour_pos]
	away_idx = away
	_spawn_players()
	reset_for_kickoff(first_kicker)
	if mode == "tournament":
		ui.show_message("TORNEO URT · Fecha %d/%d · %s vs %s" %
			[tour_pos + 1, tour_fixture.size(), _club_name(0), _club_name(1)], 3.0)


func return_to_menu() -> void:
	for p in players:
		p.queue_free()
	players.clear()
	controlled = null
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
	phase = Phase.PLAY
	ui.show_message("¡A jugar!", 1.4)


# ─── Loop principal ─────────────────────────────────────────────────────────
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

	match phase:
		Phase.MENU:
			pass
		Phase.KICKOFF:
			phase_t -= delta
			if phase_t <= 0.0:
				_do_kickoff()
		Phase.PLAY:
			clock += delta
			_check_clock()
			_check_boundaries()
		Phase.BREAKDOWN:
			phase_t -= delta
			if phase_t <= 0.0:
				_resolve_breakdown()
		Phase.SCRUM:
			phase_t -= delta
			if phase_t <= 0.0:
				_resolve_scrum()
		Phase.LINEOUT:
			phase_t -= delta
			if phase_t <= 0.0:
				_resolve_lineout()
		Phase.PENALTY:
			phase_t -= delta
			if pending_team == 0:
				# el jugador decide: tap rápido (Espacio) o a los palos (K)
				if _pen_in_range() and Input.is_action_just_pressed("kick"):
					_setup_penalty_goal()
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


func _check_clock() -> void:
	if clock < HALF_LEN or mode == "practice":
		return
	if half == 1:
		half = 2
		clock = 0.0
		attack_dir = [-attack_dir[0], -attack_dir[1]]
		phase = Phase.BETWEEN
		phase_t = 3.0
		_whistle()
		ui.show_message("¡Entretiempo! Cambian de campo", 2.8)
	else:
		phase = Phase.END
		_whistle()
		if mode == "tournament":
			if score[0] > score[1]:
				tour_wins += 1
			else:
				tour_losses += 1
			ui.show_message(
				"FINAL · %s %d — %d %s · Torneo %dG-%dP · R fecha siguiente · M menú"
				% [_club_name(0), score[0], score[1], _club_name(1),
				tour_wins, tour_losses], 999.0)
		else:
			ui.show_message("FINAL · %s %d — %d %s · R revancha · M menú" %
				[_club_name(0), score[0], score[1], _club_name(1)], 999.0)


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


func _on_try(team: int) -> void:
	score[team] += 5
	last_scoring_team = team
	conv_spot_x = ball.carrier.global_position.x
	phase = Phase.SCORE
	phase_t = 2.0
	var scorer := ball.carrier
	celebrating = scorer
	ball.release()
	if scorer != null:
		ball.global_position = scorer.global_position + Vector3(0, 0.3, 0)
		scorer.tackled = 0.0
	for p in players:
		p.tackled = 0.0
	_whistle()
	if sfx_cheer.stream != null:
		sfx_cheer.play()
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
	kicker.global_position = conv_kick_pos - Vector3(0, 0, conv_dir * 2.0)
	kicker.facing = Vector3(0, 0, conv_dir)
	kicker.hold_pos = kicker.global_position
	for p in players:
		if p != kicker:
			p.hold_pos = Vector3(clampf(p.global_position.x, -30, 30), 0.0,
				clampf(p.global_position.z, -46, 46))
	ball.freeze = true
	ball.global_position = conv_kick_pos + Vector3(0, 0.2, 0)
	ball.linear_velocity = Vector3.ZERO
	cam.set_override(conv_kick_pos + Vector3(0, 4.5, -conv_dir * 10.5),
		Vector3(0, 3.4, conv_dir * TRY_Z))
	phase = Phase.CONVERSION
	conv_done_flag = false
	if conv_team == 0:
		conv_state = ConvState.AIM
		conv_aim = 0.0
		conv_aim_dir = 1.0
		ui.conv_show()
		ui.conv_set_instr("ESPACIO: fijar dirección")
	else:
		conv_state = ConvState.WAIT_AI
		conv_t = 1.6


func _update_conversion(delta: float) -> void:
	match conv_state:
		ConvState.AIM:
			conv_aim += conv_aim_dir * delta * 1.5
			if conv_aim > 1.0:
				conv_aim = 1.0
				conv_aim_dir = -1.0
			elif conv_aim < -1.0:
				conv_aim = -1.0
				conv_aim_dir = 1.0
			ui.conv_set_aim(conv_aim)
			if Input.is_action_just_pressed("pass"):
				conv_state = ConvState.POWER
				conv_power = 0.0
				conv_power_dir = 1.0
				ui.conv_set_instr("ESPACIO: potencia")
		ConvState.POWER:
			conv_power += conv_power_dir * delta * 1.4
			if conv_power > 1.0:
				conv_power = 1.0
				conv_power_dir = -1.0
			elif conv_power < 0.0:
				conv_power = 0.0
				conv_power_dir = 1.0
			ui.conv_set_power(conv_power)
			if Input.is_action_just_pressed("pass"):
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
				reset_for_kickoff(1 - conv_team)


func _conv_execute() -> void:
	ui.conv_hide()
	ball.release()
	ball.global_position = conv_kick_pos + Vector3(0, 0.3, 0)
	var a := conv_aim * 0.5
	var dir := Vector3(sin(a), 0.0, cos(a) * conv_dir).normalized()
	var sp := 11.0 + conv_power * 16.0
	ball.linear_velocity = dir * sp + Vector3(0, 7.5 + conv_power * 5.0, 0)
	ball.angular_velocity = Vector3(-conv_dir, 0, 0) * 12.0
	ball.release_guard = 0.4
	ball.last_touch_team = conv_team
	conv_prev_z = ball.global_position.z
	conv_state = ConvState.FLY


# ─── Eventos reglamentarios ─────────────────────────────────────────────────
func on_tackle(tackler: RugbyPlayer, carrier: RugbyPlayer) -> void:
	if phase != Phase.PLAY or carrier.tackled > 0.0:
		return
	tackler.tackled = 1.2
	carrier.tackled = 1.2
	pending_spot = carrier.global_position
	ruck_team = carrier.team
	ruck_dir = int(attack_dir[carrier.team])
	var support := _nearest(carrier.team, carrier.global_position, carrier, 14.0)
	if support != null and rng.randf() < 0.85:
		pending_team = carrier.team
	else:
		pending_team = 1 - carrier.team
	phase = Phase.BREAKDOWN
	phase_t = 1.15
	ui.show_message("¡PLACAJE!", 1.0)


func _resolve_breakdown() -> void:
	# penal de ruck para el equipo atacante (10%)
	if rng.randf() < 0.1:
		var adv := pending_spot + Vector3(0, 0, float(ruck_dir) * 10.0)
		adv.z = clampf(adv.z, -TRY_Z + 6.0, TRY_Z - 6.0)
		_event_penalty(ruck_team, adv,
			"¡PENAL para %s! Infracción en el ruck" % _club_name(ruck_team))
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


func on_forward_pass(thrower: RugbyPlayer) -> void:
	_event_scrum(1 - thrower.team, thrower.global_position,
		"¡Pase adelantado! Scrum para %s" % _club_name(1 - thrower.team))


func on_knock_on(player: RugbyPlayer) -> void:
	_event_scrum(1 - player.team, player.global_position,
		"¡Knock-on! Scrum para %s" % _club_name(1 - player.team))


func _event_scrum(feed_team: int, spot: Vector3, msg: String) -> void:
	if phase != Phase.PLAY and phase != Phase.BREAKDOWN:
		return
	ui.show_message(msg, 2.2)
	_whistle()
	pending_team = feed_team
	pending_spot = Vector3(clampf(spot.x, -FIELD_HALF_W + 6.0, FIELD_HALF_W - 6.0),
		0.0, clampf(spot.z, -TRY_Z + 7.0, TRY_Z - 7.0))
	ball.release()
	ball.freeze = true
	ball.global_position = pending_spot + Vector3(0, 0.25, 0)
	for p in players:
		p.hold_pos = p.global_position
	phase = Phase.SCRUM
	phase_t = 2.4


func _resolve_scrum() -> void:
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
	phase = Phase.PLAY


func _event_penalty(team: int, spot: Vector3, msg: String) -> void:
	ui.show_message(msg, 2.2)
	_whistle()
	pending_team = team
	pending_spot = spot
	# acumulación de penales → tarjeta amarilla
	var offender := 1 - team
	pen_count[offender] += 1
	if pen_count[offender] >= 2:
		var card := _nearest(offender, spot, null, 999.0)
		if card != null:
			card.sin_bin_t = 45.0
			card.tackled = 0.0
			card.global_position = Vector3(
				signf(spot.x + 1.0) * (FIELD_HALF_W + 6.0), 0.0, spot.z)
			pen_count[offender] = 0
			ui.show_message("¡TARJETA AMARILLA! %s juega con 14" %
				_club_name(offender), 3.0)
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


func _resolve_penalty() -> void:
	# la IA decide a los palos si está en rango
	if pending_team == 1 and _pen_in_range() and rng.randf() < 0.45:
		_setup_penalty_goal()
		return
	var p := _nearest(pending_team, pending_spot, null, 999.0)
	if p != null:
		ball.set_carrier(p)
		p.hold_pos = pending_spot
	ui.flash_hint("¡Penal jugado rápido!")
	phase = Phase.PLAY


func _tour_next() -> void:
	tour_pos += 1
	if tour_pos >= tour_fixture.size():
		var res := "¡TORNEO TERMINADO! %s: %d ganados · %d perdidos" % [
			_club_name(0), tour_wins, tour_losses]
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
	var bd := 999.0
	for p in players:
		if p.team != carrier.team or p == carrier or p.tackled > 0.0 \
				or p.sin_bin_t > 0.0:
			continue
		var fwd := (p.global_position.z - carrier.global_position.z) * d
		if behind_only and fwd > 0.4:
			continue
		var dist := carrier.global_position.distance_to(p.global_position)
		if dist < 2.0:
			continue
		if dist < bd:
			bd = dist
			best = p
	return best


func _select_controlled() -> void:
	var want: RugbyPlayer = null
	if ball.carrier != null and ball.carrier.team == 0:
		want = ball.carrier
	elif phase == Phase.PLAY or phase == Phase.KICKOFF:
		want = _nearest(0, ball.global_position, null, 999.0)
	if want != controlled:
		controlled = want


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
