extends CharacterBody3D
class_name RugbyPlayer

const BASE_SPEED := 7.4
const SPRINT_SPEED := 9.8
const AI_CHASE := 7.8
const AI_JOG := 6.4

var game: RugbyGame
var team := 0
var index := 0
var rating := 1.0
var tackled := 0.0
var cool_pass := 0.0
var facing := Vector3(0, 0, 1)
var hold_pos := Vector3.ZERO
var col_primary := Color(0.2, 0.4, 0.9)
var col_secondary := Color(0.1, 0.1, 0.1)
var col_shorts := Color(0.9, 0.9, 0.9)
var alt_kit := false                  # kit visitante alternativo si hay choque de colores

var visual: Node3D
var marker: MeshInstance3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var bob_t := 0.0


func is_forward() -> bool:
	return index < 8


func is_nine() -> bool:
	return index == 8


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1   # solo suelo: los jugadores no se empujan (evita tembleo/pilas)
	floor_snap_length = 0.3
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4 if is_forward() else 0.34
	shape.height = 1.75
	cs.shape = shape
	cs.position.y = 0.85
	add_child(cs)
	_build_visual()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _capsule(parent: Node3D, r: float, h: float, y: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	mi.mesh = m
	mi.position.y = y
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _build_visual() -> void:
	visual = Node3D.new()
	add_child(visual)
	var bulk := 1.08 if is_forward() else 0.94
	var jersey := col_secondary if alt_kit else col_primary
	var trim := col_primary if alt_kit else col_secondary
	# tono de piel variado por jugador
	var skin_t := fmod(float(index * 7 + team * 3), 10.0) / 10.0
	var skin := Color(0.93, 0.78, 0.62).lerp(Color(0.42, 0.29, 0.18), skin_t)
	var skin_mat := _mat(skin)
	var jersey_mat := _mat(jersey)
	var trim_mat := _mat(trim)
	var shorts_mat := _mat(col_shorts)

	# piernas (pivote en la cadera para animar la zancada)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.13 * bulk, 0.98, 0.0)
		visual.add_child(leg)
		_capsule(leg, 0.1, 0.62, -0.4, skin_mat)
		_capsule(leg, 0.105, 0.22, -0.66, trim_mat)     # medias
		_box(leg, Vector3(0.2, 0.1, 0.3), Vector3(0, -0.9, 0.05), _mat(Color(0.15, 0.15, 0.15)))  # botines
		if side < 0.0:
			leg_l = leg
		else:
			leg_r = leg

	# pantalón
	_box(visual, Vector3(0.42 * bulk, 0.3, 0.32 * bulk), Vector3(0, 1.02, 0), shorts_mat)

	# torso + banda de la camiseta
	_box(visual, Vector3(0.48 * bulk, 0.62, 0.3 * bulk), Vector3(0, 1.38, 0), jersey_mat)
	_box(visual, Vector3(0.5 * bulk, 0.16, 0.32 * bulk), Vector3(0, 1.44, 0), trim_mat)

	# brazos (pivote en el hombro)
	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * (0.28 * bulk + 0.08), 1.6, 0.0)
		visual.add_child(arm)
		_capsule(arm, 0.085, 0.5, -0.28, jersey_mat)   # manga
		_capsule(arm, 0.075, 0.2, -0.58, skin_mat)     # antebrazo
		if side < 0.0:
			arm_l = arm
		else:
			arm_r = arm

	# cabeza
	_capsule(visual, 0.14, 0.3, 1.88, skin_mat)

	# cono marcador del jugador controlado
	marker = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.32
	cone.height = 0.5
	marker.mesh = cone
	marker.rotation.x = PI
	marker.position.y = 2.5
	marker.material_override = _mat(Color(1.0, 0.85, 0.1))
	visual.add_child(marker)


func _process(_delta: float) -> void:
	marker.visible = game != null and game.controlled == self


func carry_point() -> Vector3:
	return global_position + Vector3(0, 1.1, 0) + facing * 0.42


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

	var wish := _desired_velocity()
	velocity.x = wish.x
	velocity.z = wish.z
	_apply_gravity_move(delta)

	var hs := Vector2(velocity.x, velocity.z).length()
	if hs > 0.4:
		# facing suavizado: evita que el balón/la vista tiemblen
		facing = facing.lerp(Vector3(velocity.x, 0.0, velocity.z).normalized(),
			delta * 10.0).normalized()
	_update_visual(delta, hs)
	_try_pickup()
	_try_tackle()


func _apply_gravity_move(delta: float) -> void:
	velocity.y -= 24.0 * delta
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = -0.5
	move_and_slide()
	global_position.y = maxf(0.0, global_position.y)


func _desired_velocity() -> Vector3:
	match game.phase:
		RugbyGame.Phase.SCRUM, RugbyGame.Phase.LINEOUT:
			var t := game.get_formation_pos(self)
			return _seek(t, AI_JOG * 1.1) if t != global_position else Vector3.ZERO
		RugbyGame.Phase.PLAY, RugbyGame.Phase.BREAKDOWN:
			pass
		_:
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
	if game.phase == RugbyGame.Phase.BREAKDOWN:
		return _ruck_ai()
	var ai_speed := AI_CHASE * rating
	if b.carrier == null:
		if _team_rank(b.global_position) < 3 and b.global_position.y < 3.2:
			return _seek(b.global_position, ai_speed)
		return _hold()
	if b.carrier.team == team:
		if b.carrier == self:
			return _carrier_ai()
		return _support_ai()
	return _defense_ai()


func _ruck_ai() -> Vector3:
	var spot := game.pending_spot
	var d := float(game.ruck_dir)
	if team == game.ruck_team:
		if is_nine():
			return _seek(spot - Vector3(0, 0, d * 2.0), AI_CHASE)
		if is_forward() and _team_rank(spot) < 3:
			return _seek(spot, AI_CHASE)
		return _hold()
	if is_forward() and _team_rank(spot) < 2:
		return _seek(spot + Vector3(0, 0, d * 0.8), AI_CHASE)
	var lane := -28.0 + index * 4.0
	var behind := spot - Vector3(0, 0, d * 3.0)
	return _seek(Vector3(clampf(lane, -30, 30), 0.0, behind.z), AI_JOG)


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
	var goal := Vector3(0.0, 0.0, d * 62.0)
	var to := goal - global_position
	to.y = 0.0
	var dir := to.normalized()
	var side := Vector3(-d, 0.0, 0.0)

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

	if nearest_d < 2.8 and cool_pass <= 0.0:
		var target := game.find_pass_target(self, true)
		if target != null:
			game.ball.throw_to(target, self)
			cool_pass = 1.1
			return Vector3.ZERO

	if nearest_d < 5.5:
		var evade := side * (1.0 if side.dot(nearest_rel) < 0.0 else -1.0)
		if (left < right) != (evade.dot(side) > 0.0):
			evade = -evade
		dir = (dir * 0.55 + evade * 0.85).normalized()

	return dir * AI_CHASE * rating


func _support_ai() -> Vector3:
	var c := game.ball.carrier
	var d := float(game.attack_dir[team])
	var lane := lerpf(-30.0, 30.0, index / 14.0)
	var depth := 3.5 + float(index % 4) * 2.5
	var target := c.global_position + Vector3(lane, 0.0, -d * depth)
	target.x = clampf(target.x, -31.0, 31.0)
	if (target.z - c.global_position.z) * d > -1.5:
		target.z = c.global_position.z - d * 1.5
	return _seek(target, AI_JOG)


func _defense_ai() -> Vector3:
	var c := game.ball.carrier
	var cdir := float(game.attack_dir[c.team])
	if _team_rank(c.global_position) < 3:
		return _seek(c.global_position, AI_CHASE * rating)
	if (global_position.z - c.global_position.z) * cdir < -5.0:
		return _seek(c.global_position, AI_CHASE * 0.95 * rating)
	var lane := lerpf(-32.0, 32.0, index / 14.0)
	var line_z := clampf(c.global_position.z + cdir * 7.0, -48.0, 48.0)
	var target := Vector3(clampf(lane + c.global_position.x * 0.35, -32.0, 32.0), 0.0, line_z)
	return _seek(target, AI_JOG * rating)


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
		if b.pass_from != null and b.pass_from.team == team and self != game.controlled:
			var chance := 0.1 if b.pass_from != game.controlled else 0.04
			if game.rng.randf() < chance:
				game.on_knock_on(self)
				return
		b.set_carrier(self)


func _try_tackle() -> void:
	var c := game.ball.carrier
	if c == null or c.team == team or c.tackled > 0.0:
		return
	if game.phase != RugbyGame.Phase.PLAY:
		return
	var reach := RugbyGame.TACKLE_RANGE * (1.0 if game.controlled != self else 1.25)
	if global_position.distance_to(c.global_position) < reach:
		game.on_tackle(self, c)


func _do_pass() -> void:
	var target := game.find_pass_target(self, true)
	if target == null:
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


# ─── Visual (animación de carrera procedural) ───────────────────────────────
func _update_visual(delta: float, h_speed: float) -> void:
	bob_t += delta * (5.0 + h_speed * 0.9)
	var run := clampf(h_speed / SPRINT_SPEED, 0.0, 1.0)
	if tackled > 0.0:
		visual.rotation.x = lerpf(visual.rotation.x, -1.4, delta * 8.0)
		visual.position.y = lerpf(visual.position.y, -0.7, delta * 8.0)
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, delta * 6.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, delta * 6.0)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, delta * 6.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, delta * 6.0)
		return
	visual.rotation.x = lerpf(visual.rotation.x, run * 0.16, delta * 8.0)
	visual.position.y = lerpf(visual.position.y, 0.0, delta * 8.0) \
		+ absf(sin(bob_t)) * 0.05 * run
	var swing := sin(bob_t) * (0.85 * run)
	leg_l.rotation.x = swing
	leg_r.rotation.x = -swing
	arm_l.rotation.x = -swing * 0.7
	arm_r.rotation.x = swing * 0.7
	# cuando tiene el balón, brazos hacia adelante como sosteniéndolo
	if game != null and game.ball != null and game.ball.carrier == self:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -1.1, delta * 10.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.1, delta * 10.0)
	if h_speed > 0.4:
		visual.rotation.y = lerp_angle(visual.rotation.y,
			atan2(facing.x, facing.z), delta * 10.0)
	marker.position.y = 2.5 + sin(bob_t * 0.6) * 0.12
