extends Node3D
class_name RugbyGame

# ─── Constantes del juego ───────────────────────────────────────────────────
const TEAM_NAMES := ["AZUL", "ROJO"]
const TEAM_COLORS := [Color(0.16, 0.42, 0.95), Color(0.92, 0.18, 0.13)]
const FIELD_HALF_W := 34.0        # semiancho de la cancha (touchlines en |x| = 34)
const TRY_Z := 50.0               # líneas de try en |z| = 50
const DEAD_Z := 58.0              # línea de pelota muerta
const TEAM_SIZE := 5
const HALF_LEN := 150.0           # segundos por tiempo
const TACKLE_RANGE := 1.3
const PICKUP_RANGE := 1.4

enum Phase { KICKOFF, PLAY, BREAKDOWN, SCORE, BETWEEN, END }

var players: Array[RugbyPlayer] = []
var ball: RugbyBall
var controlled: RugbyPlayer = null
var cam: RugbyCam
var ui: RugbyUI

var score := [0, 0]
var half := 1
var clock := 0.0
var attack_dir := [1, -1]          # dirección de ataque de cada equipo en Z
var phase := Phase.KICKOFF
var phase_t := 0.0
var kick_team := 1
var first_kicker := 1
var last_scoring_team := -1
var pending_team := -1             # equipo que recibe tras un silbato
var pending_spot := Vector3.ZERO
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_register_input()
	RugbyField.build(self)
	_spawn_ball()
	_spawn_players()
	cam = RugbyCam.new()
	cam.game = self
	add_child(cam)
	ui = RugbyUI.new()
	add_child(ui)
	ui.set_info("WASD mover · Shift sprint · Espacio pasar (¡hacia atrás!) · K patada · Esc pausa · R reiniciar")
	start_match()


# ─── Input ──────────────────────────────────────────────────────────────────
func _register_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("sprint", [KEY_SHIFT])
	_add_key_action("pass", [KEY_SPACE])
	_add_key_action("kick", [KEY_K])
	_add_key_action("restart", [KEY_R])
	_add_key_action("pause", [KEY_ESCAPE, KEY_P])


func _add_key_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


# ─── Setup ──────────────────────────────────────────────────────────────────
func _spawn_ball() -> void:
	ball = RugbyBall.new()
	ball.game = self
	add_child(ball)


func _spawn_players() -> void:
	for team in 2:
		for i in TEAM_SIZE:
			var p := RugbyPlayer.new()
			p.game = self
			p.team = team
			p.index = i
			add_child(p)
			players.append(p)


func start_match() -> void:
	score = [0, 0]
	half = 1
	clock = 0.0
	attack_dir = [1, -1]
	first_kicker = 1   # el equipo del jugador (AZUL) recibe el saque inicial
	reset_for_kickoff(first_kicker)


func reset_for_kickoff(kt: int) -> void:
	phase = Phase.KICKOFF
	phase_t = 1.0
	kick_team = kt
	var kd := float(attack_dir[kt])
	for p in players:
		p.tackled = 0.0
		p.cool_pass = 0.0
		p.velocity = Vector3.ZERO
		if p.team == kt:
			# equipo que saca: detrás de la mitad de cancha, propio lado
			var pos := Vector3.ZERO
			if p.index == 0:
				pos = Vector3(0.0, 0.0, -kd * 1.2)          # pateador
			else:
				var col := (p.index - 1) % 4
				pos = Vector3(-15.0 + col * 10.0, 0.0, -kd * 6.0)
			p.global_position = pos
		else:
			# equipo receptor: desplegado en su campo
			var recv_z: float = [18.0, 34.0, 30.0, 42.0, 25.0][p.index]
			var recv_x: float = [0.0, -14.0, 14.0, 2.0, -26.0][p.index]
			p.global_position = Vector3(recv_x, 0.0, kd * recv_z)
		p.hold_pos = p.global_position
		p.facing = Vector3(0.0, 0.0, kd if p.team == kt else -kd)
		p.visual.rotation.y = atan2(p.facing.x, p.facing.z)
	ball.release()
	ball.global_position = Vector3(0.0, 0.9, -kd * 1.2)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = true
	_select_controlled()
	ui.show_message("¡Saque de %s!" % TEAM_NAMES[kt], 1.6)


func _do_kickoff() -> void:
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
	if Input.is_action_just_pressed("pause") and phase != Phase.END:
		get_tree().paused = not get_tree().paused
		ui.set_paused(get_tree().paused)
	if get_tree().paused:
		return
	if Input.is_action_just_pressed("restart"):
		if phase == Phase.END:
			start_match()
			return

	match phase:
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
		Phase.SCORE:
			phase_t -= delta
			if phase_t <= 0.0:
				reset_for_kickoff(1 - last_scoring_team)
		Phase.BETWEEN:
			phase_t -= delta
			if phase_t <= 0.0:
				reset_for_kickoff(1 - first_kicker)
		Phase.END:
			pass

	_select_controlled()
	_refresh_ui()


func _check_clock() -> void:
	if clock < HALF_LEN:
		return
	if half == 1:
		half = 2
		clock = 0.0
		attack_dir = [-attack_dir[0], -attack_dir[1]]
		phase = Phase.BETWEEN
		phase_t = 3.0
		ui.show_message("¡Entretiempo! Se cambian de campo", 2.8)
	else:
		phase = Phase.END
		ui.show_message("FINAL · %s %d — %d %s · R para revancha" %
			[TEAM_NAMES[0], score[0], score[1], TEAM_NAMES[1]], 999.0)


func _check_boundaries() -> void:
	if ball.carrier != null:
		var c: RugbyPlayer = ball.carrier
		var cp := c.global_position
		var d := float(attack_dir[c.team])
		if cp.z * d > TRY_Z and absf(cp.x) <= FIELD_HALF_W + 1.0:
			_on_try(c.team)
			return
		if absf(cp.x) > FIELD_HALF_W or absf(cp.z) > DEAD_Z:
			_whistle(1 - c.team, cp, "¡Touch! El portador salió de la cancha")
	else:
		var bp := ball.global_position
		if absf(bp.x) > FIELD_HALF_W + 0.3 or absf(bp.z) > DEAD_Z:
			var recv := 1 - ball.last_touch_team if ball.last_touch_team >= 0 else 0
			_whistle(recv, bp, "¡El balón salió! Posesión para %s" % TEAM_NAMES[recv])


func _on_try(team: int) -> void:
	score[team] += 7   # try (5) + conversión automática (2)
	last_scoring_team = team
	phase = Phase.SCORE
	phase_t = 3.2
	var scorer := ball.carrier
	ball.release()
	if scorer != null:
		ball.global_position = scorer.global_position + Vector3(0, 0.3, 0)
	ui.show_message("¡¡¡TRY de %s!!! +7 con la conversión" % TEAM_NAMES[team], 3.0)


func on_tackle(tackler: RugbyPlayer, carrier: RugbyPlayer) -> void:
	if phase != Phase.PLAY or carrier.tackled > 0.0:
		return
	tackler.tackled = 1.2
	carrier.tackled = 1.2
	pending_spot = carrier.global_position
	# ¿hay apoyo cerca? si el portador está aislado, puede haber turnover
	var support := _nearest(carrier.team, carrier.global_position, carrier, 14.0)
	if support != null and rng.randf() < 0.85:
		pending_team = carrier.team
	else:
		pending_team = 1 - carrier.team
	phase = Phase.BREAKDOWN
	phase_t = 1.15
	ui.show_message("¡PLACAJE!", 1.0)


func on_forward_pass(thrower: RugbyPlayer) -> void:
	ui.show_message("¡Pase adelantado! Posesión para %s" % TEAM_NAMES[1 - thrower.team], 2.0)
	_whistle(1 - thrower.team, thrower.global_position, "")


func _whistle(recv_team: int, spot: Vector3, msg: String) -> void:
	if phase != Phase.PLAY:
		return
	if msg != "":
		ui.show_message(msg, 2.0)
	pending_team = recv_team
	pending_spot = Vector3(clampf(spot.x, -FIELD_HALF_W + 2.0, FIELD_HALF_W - 2.0), 0.0,
		clampf(spot.z, -TRY_Z + 4.0, TRY_Z - 4.0))
	ball.release()
	ball.freeze = true
	ball.global_position = pending_spot + Vector3(0, 1.0, 0)
	phase = Phase.BREAKDOWN
	phase_t = 1.1


func _resolve_breakdown() -> void:
	var p := _nearest(pending_team, pending_spot, null, 999.0)
	if p == null:
		p = _nearest(pending_team, Vector3.ZERO, null, 999.0)
	if p != null:
		ball.set_carrier(p)
	phase = Phase.PLAY


func _nearest(team: int, pos: Vector3, exclude: RugbyPlayer, maxd: float) -> RugbyPlayer:
	var best: RugbyPlayer = null
	var bd := maxd
	for p in players:
		if p.team != team or p == exclude or p.tackled > 0.0:
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
		if p.team != carrier.team or p == carrier or p.tackled > 0.0:
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


# ─── Utilidades ─────────────────────────────────────────────────────────────
func cam_move_dir(iv: Vector2) -> Vector3:
	var b := cam.global_transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var fwd := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	return (right * iv.x - fwd * iv.y).normalized()


func _refresh_ui() -> void:
	ui.set_score(TEAM_NAMES[0], score[0], score[1], TEAM_NAMES[1])
	var m := int(clock) / 60
	var s := int(clock) % 60
	ui.set_clock("%dT  %02d:%02d" % [half, m, s])
