extends CharacterBody3D
class_name RugbyPlayer

const BASE_SPEED := 7.4
const SPRINT_SPEED := 9.8
const AI_CHASE := 7.8
const AI_JOG := 6.4
const SUPPORT_LANES := [-16.0, -8.0, 0.0, 8.0, 16.0]
const DEF_LANES := [-18.0, -9.0, 0.0, 9.0, 18.0]

var game: RugbyGame
var team := 0
var index := 0
var tackled := 0.0
var cool_pass := 0.0
var facing := Vector3(0, 0, 1)
var hold_pos := Vector3.ZERO

var visual: Node3D
var marker: MeshInstance3D
var bob_t := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.7
	cs.shape = shape
	cs.position.y = 0.85
	add_child(cs)
	_build_visual()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _build_visual() -> void:
	visual = Node3D.new()
	add_child(visual)

	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.5
	body.mesh = cap
	body.position.y = 0.92
	body.material_override = _mat(RugbyGame.TEAM_COLORS[team])
	visual.add_child(body)

	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.21
	sm.height = 0.42
	head.mesh = sm
	head.position.y = 1.82
	head.material_override = _mat(Color(0.85, 0.68, 0.52))
	visual.add_child(head)

	# cono marcador del jugador controlado
	marker = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.3
	cone.height = 0.45
	marker.mesh = cone
	marker.rotation.x = PI
	marker.position.y = 2.55
	marker.material_override = _mat(Color(1.0, 0.85, 0.1))
	visual.add_child(marker)


func _process(_delta: float) -> void:
	marker.visible = game != null and game.controlled == self


func carry_point() -> Vector3:
	return global_position + Vector3(0, 0.95, 0) + facing * 0.45


func _physics_process(delta: float) -> void:
	if game == null:
		return
	cool_pass = maxf(0.0, cool_pass - delta)
	if tackled > 0.0:
		tackled -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity_move(delta)
		_update_visual(delta, 0.0)
		return

	var wish := _desired_velocity(delta)
	velocity.x = wish.x
	velocity.z = wish.z
	_apply_gravity_move(delta)

	var hs := Vector2(velocity.x, velocity.z).length()
	if hs > 0.5:
		facing = Vector3(velocity.x, 0.0, velocity.z).normalized()
	_update_visual(delta, hs)
	_try_pickup()
	_try_tackle()


func _apply_gravity_move(delta: float) -> void:
	velocity.y -= 24.0 * delta
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = -0.5
	move_and_slide()
	global_position.y = maxf(0.0, global_position.y)


func _desired_velocity(_delta: float) -> Vector3:
	if game.phase != RugbyGame.Phase.PLAY and game.phase != RugbyGame.Phase.BREAKDOWN:
		return Vector3.ZERO
	if game.controlled == self:
		var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var d := game.cam_move_dir(iv)
		var sp := SPRINT_SPEED if Input.is_action_pressed("sprint") else BASE_SPEED
		if game.ball.carrier == self:
			if Input.is_action_just_pressed("pass"):
				_do_pass()
			if Input.is_action_just_pressed("kick"):
				_do_kick()
		return d * sp
	return _ai_velocity()


# ─── IA ─────────────────────────────────────────────────────────────────────
func _ai_velocity() -> Vector3:
	var b := game.ball
	if b.carrier == null:
		# balón suelto: los dos más cercanos de cada equipo van a buscarlo
		if _team_rank(b.global_position) < 2 and b.global_position.y < 3.2:
			return _seek(b.global_position, AI_CHASE)
		return _hold()
	if b.carrier.team == team:
		if b.carrier == self:
			return _carrier_ai()
		return _support_ai()
	return _defense_ai()


func _team_rank(pos: Vector3) -> int:
	var r := 0
	var my_d := global_position.distance_squared_to(pos)
	for p in game.players:
		if p.team == team and p != self and p.tackled <= 0.0 \
				and p.global_position.distance_squared_to(pos) < my_d:
			r += 1
	return r


func _seek(target: Vector3, sp: float) -> Vector3:
	var diff := target - global_position
	diff.y = 0.0
	var dist := diff.length()
	if dist < 0.8:
		return Vector3.ZERO
	return diff.normalized() * sp * minf(1.0, dist / 4.0 + 0.25)


func _hold() -> Vector3:
	return _seek(hold_pos, AI_JOG * 0.6)


func _carrier_ai() -> Vector3:
	var d := float(game.attack_dir[team])
	var goal := Vector3(0.0, 0.0, d * 60.0)
	var to := goal - global_position
	to.y = 0.0
	var dir := to.normalized()
	var side := Vector3(-d, 0.0, 0.0)   # lateral relativo a la dirección de ataque

	var nearest_d := 999.0
	var nearest_rel := Vector3.ZERO
	var left := 0
	var right := 0
	for p in game.players:
		if p.team == team or p.tackled > 0.0:
			continue
		var rel := p.global_position - global_position
		rel.y = 0.0
		var dist := rel.length()
		if dist < 7.0:
			if side.dot(rel) > 0.0:
				left += 1
			else:
				right += 1
			if dist < nearest_d:
				nearest_d = dist
				nearest_rel = rel

	# pase bajo presión (solo a apoyos estrictamente detrás → siempre legal)
	if nearest_d < 2.8 and cool_pass <= 0.0:
		var target := game.find_pass_target(self, true)
		if target != null:
			game.ball.throw_to(target, self)
			cool_pass = 1.2
			return Vector3.ZERO

	# esquivar al defensor más cercano yendo hacia el lado más libre
	if nearest_d < 5.5:
		var evade := side * (1.0 if side.dot(nearest_rel) < 0.0 else -1.0)
		if (left < right) != (evade.dot(side) > 0.0):
			evade = -evade
		dir = (dir * 0.55 + evade * 0.85).normalized()

	return dir * AI_CHASE


func _support_ai() -> Vector3:
	var c := game.ball.carrier
	var d := float(game.attack_dir[team])
	var lane: float = SUPPORT_LANES[index % 5]
	var depth := 3.5 + float(index % 3) * 3.0
	var target := c.global_position + Vector3(lane, 0.0, -d * depth)
	target.x = clampf(target.x, -30.0, 30.0)
	# nunca por delante del portador (offside espiritual / línea de pase)
	if (target.z - c.global_position.z) * d > -1.5:
		target.z = c.global_position.z - d * 1.5
	return _seek(target, AI_JOG)


func _defense_ai() -> Vector3:
	var c := game.ball.carrier
	var cdir := float(game.attack_dir[c.team])
	# los dos más cercanos presionan al portador
	if _team_rank(c.global_position) < 2:
		return _seek(c.global_position, AI_CHASE)
	# si el portador ya nos superó, todos persiguen
	if (global_position.z - c.global_position.z) * cdir < -5.0:
		return _seek(c.global_position, AI_CHASE * 0.95)
	# resto: línea defensiva delante del portador
	var lane: float = DEF_LANES[index % 5]
	var line_z := clampf(c.global_position.z + cdir * 7.0, -48.0, 48.0)
	var target := Vector3(clampf(lane + c.global_position.x * 0.35, -31.0, 31.0), 0.0, line_z)
	return _seek(target, AI_JOG)


func _try_pickup() -> void:
	var b := game.ball
	if b.carrier != null or not b.can_pickup() or tackled > 0.0:
		return
	if game.phase != RugbyGame.Phase.PLAY:
		return
	var r := RugbyGame.PICKUP_RANGE + (0.6 if b.global_position.y > 1.2 else 0.0)
	var dxz := Vector2(b.global_position.x - global_position.x,
		b.global_position.z - global_position.z).length()
	if dxz < r:
		b.set_carrier(self)


func _try_tackle() -> void:
	var c := game.ball.carrier
	if c == null or c.team == team or c.tackled > 0.0:
		return
	if game.phase != RugbyGame.Phase.PLAY:
		return
	if global_position.distance_to(c.global_position) < RugbyGame.TACKLE_RANGE:
		game.on_tackle(self, c)


func _do_pass() -> void:
	var target := game.find_pass_target(self, true)
	if target == null:
		# sin apoyo detrás: cualquier compañero → si está adelante es pase ilegal
		target = game.find_pass_target(self, false)
		if target == null:
			game.ui.flash_hint("¡Sin compañeros cerca!")
			return
	var fwd := (target.global_position.z - global_position.z) * float(game.attack_dir[team])
	if fwd > 0.4:
		game.on_forward_pass(self)
		return
	game.ball.throw_to(target, self)
	cool_pass = 0.4


func _do_kick() -> void:
	var d := float(game.attack_dir[team])
	var dir := Vector3(-global_position.x * 0.015, 0.0, d).normalized()
	game.ball.kicked(self, dir)


# ─── Visual ─────────────────────────────────────────────────────────────────
func _update_visual(delta: float, h_speed: float) -> void:
	bob_t += delta * (4.0 + h_speed)
	if tackled > 0.0:
		visual.rotation.x = lerpf(visual.rotation.x, -1.35, delta * 8.0)
		visual.position.y = lerpf(visual.position.y, -0.45, delta * 8.0)
	else:
		visual.rotation.x = lerpf(visual.rotation.x, 0.0, delta * 8.0)
		visual.position.y = lerpf(visual.position.y, 0.0, delta * 8.0)
		var run := clampf(h_speed / SPRINT_SPEED, 0.0, 1.0)
		visual.position.y += absf(sin(bob_t)) * 0.09 * run
		visual.rotation.x -= run * 0.12
	if h_speed > 0.5:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(facing.x, facing.z), delta * 10.0)
	marker.position.y = 2.55 + sin(bob_t * 0.6) * 0.12
