extends CharacterBody3D
class_name RugbyPlayer

const BASE_SPEED := 7.4
const SPRINT_SPEED := 9.8
const AI_CHASE := 8.7
const AI_JOG := 7.0

var game: RugbyGame
var team := 0
var index := 0
var pname := ""                   # apellido del plantel URT
var rating := 1.0
var tackled := 0.0
var cool_pass := 0.0
var cool_fend := 0.0
var cool_kick := 0.0
var dive_t := 0.0                  # tiempo restante del lance de placaje
var dive_dir := Vector3(0, 0, 1)
var dive_cd := 0.0                  # cooldown tras lanzarse
var step_t := 0.0                  # burst del sidestep
var step_dir := Vector3(0, 0, 1)
var step_cd := 0.0
var surge_t := 0.0
var stamina := 1.0                 # energía: el sprint cansa
var sprint_on := false              # modo alternar (opción)
var kick_anim_t := 0.0              # animación de patada del pateador
var froze_t := 0.0                  # congelado por un amague (dummy)
var stat_tries := 0
var stat_tackles := 0
var stat_metros := 0.0
var facing := Vector3(0, 0, 1)
var wide_mem := 1.0                   # último lado ancho visto
var pass_anim_t := 0.0                # gesto del pase
var hold_pos := Vector3.ZERO
var col_primary := Color(0.2, 0.4, 0.9)
var col_secondary := Color(0.1, 0.1, 0.1)
var col_shorts := Color(0.9, 0.9, 0.9)
var alt_kit := false                  # kit visitante alternativo si hay choque de colores
var jersey_tex: Texture2D = null      # camiseta oficial (patrón URT)
var jersey_tex_alt: Texture2D = null  # versión alternativa
var speed_mult := 1.0                 # velocidad según posición
var break_prob := 0.0                 # prob. de romper el placaje (forwards)
var sin_bin_t := 0.0                  # tiempo restante en el sin bin

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
	var skin_t := fmod(float(index * 7 + team * 3), 10.0) / 10.0
	var skin := Color(0.93, 0.78, 0.62).lerp(Color(0.42, 0.29, 0.18), skin_t)
	var skin_mat := _mat(skin)
	var jersey_mat := _mat(jersey)
	var jtex: Texture2D = jersey_tex_alt if alt_kit else jersey_tex
	if jtex != null:
		jersey_mat.albedo_texture = jtex
		jersey_mat.albedo_color = Color(1, 1, 1)
	var trim_mat := _mat(trim)
	var shorts_mat := _mat(col_shorts)

	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.13 * bulk, 0.98, 0.0)
		visual.add_child(leg)
		_capsule(leg, 0.115 * bulk, 0.34, -0.16, shorts_mat)   # muslo bajo el short
		_capsule(leg, 0.095, 0.42, -0.52, skin_mat)            # rodilla/pantorrilla
		_capsule(leg, 0.1, 0.26, -0.72, trim_mat)              # media
		_capsule(leg, 0.105, 0.07, -0.62, _mat(col_primary))   # vuelta de la media
		var boot_sel := (index * 2 + team) % 6
		var boot_c := Color(0.12, 0.12, 0.12)                  # la mayoria negros
		if boot_sel == 4:
			boot_c = Color(0.9, 0.9, 0.9)
		elif boot_sel == 5:
			boot_c = Color(0.9, 0.55, 0.1)
		_box(leg, Vector3(0.2, 0.11, 0.32), Vector3(0, -0.9, 0.05), _mat(boot_c))
		if side < 0.0:
			leg_l = leg
		else:
			leg_r = leg

	_box(visual, Vector3(0.42 * bulk, 0.3, 0.32 * bulk), Vector3(0, 1.02, 0), shorts_mat)
	_box(visual, Vector3(0.5 * bulk, 0.34, 0.34 * bulk), Vector3(0, 1.52, 0), jersey_mat)
	_box(visual, Vector3(0.44 * bulk, 0.32, 0.28 * bulk), Vector3(0, 1.2, 0), jersey_mat)
	_capsule(visual, 0.09, 0.18, 1.74, skin_mat)

	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * (0.3 * bulk + 0.06), 1.58, 0.0)
		visual.add_child(arm)
		_capsule(arm, 0.11, 0.16, -0.03, jersey_mat)    # hombro
		_capsule(arm, 0.095, 0.4, -0.26, jersey_mat)    # manga + biceps
		_capsule(arm, 0.075, 0.22, -0.56, skin_mat)     # antebrazo
		if side > 0.0 and (index * 7 + team) % 4 == 0:
			_capsule(arm, 0.08, 0.09, -0.68, trim_mat)  # munequera
		if side < 0.0:
			arm_l = arm
		else:
			arm_r = arm

	# variedad física: altura determinística por casaca
	var hvar := 0.94 + fmod(float(index * 5 + team * 2), 12.0) / 100.0 * 6.0
	if is_forward():
		hvar += 0.04
	visual.scale.y = hvar
	var hair_cols := [Color(0.08, 0.06, 0.05), Color(0.2, 0.12, 0.06),
		Color(0.38, 0.24, 0.1), Color(0.7, 0.55, 0.25), Color(0.5, 0.2, 0.08)]
	var hair_c: Color = hair_cols[(index + team) % 5]
	var hair_sel := (index * 3 + team) % 10

	# cabeza con facciones: orejas, cejas, ojos, nariz, boca
	_capsule(visual, 0.135, 0.3, 1.9, skin_mat)
	for side in [-1.0, 1.0]:
		_box(visual, Vector3(0.03, 0.07, 0.05),
			Vector3(side * 0.135, 1.89, 0), skin_mat)
		_box(visual, Vector3(0.05, 0.016, 0.012),
			Vector3(side * 0.052, 1.925, 0.115), _mat(hair_c.darkened(0.4)))
		_box(visual, Vector3(0.04, 0.02, 0.012),
			Vector3(side * 0.05, 1.898, 0.118), _mat(Color(0.08, 0.08, 0.1)))
	_box(visual, Vector3(0.045, 0.06, 0.04), Vector3(0, 1.855, 0.12),
		_mat(skin.darkened(0.06)))
	_box(visual, Vector3(0.07, 0.014, 0.012), Vector3(0, 1.778, 0.11),
		_mat(Color(0.45, 0.25, 0.22)))

	# peinados (la 1ra línea lleva casco de scrum)
	if index >= 3:
		if hair_sel < 5:                     # corte corto
			_box(visual, Vector3(0.24, 0.1, 0.25), Vector3(0, 1.99, -0.02),
				_mat(hair_c))
		elif hair_sel < 7:                   # melena
			_box(visual, Vector3(0.24, 0.1, 0.25), Vector3(0, 1.99, -0.02),
				_mat(hair_c))
			_box(visual, Vector3(0.2, 0.34, 0.1), Vector3(0, 1.78, -0.14),
				_mat(hair_c))
		elif hair_sel == 7:                  # vincha del club
			_box(visual, Vector3(0.24, 0.1, 0.25), Vector3(0, 1.99, -0.02),
				_mat(hair_c))
			_box(visual, Vector3(0.27, 0.05, 0.27), Vector3(0, 1.94, -0.01),
				trim_mat)
		# 8-9: pelado
		if hair_sel >= 5:                    # barba
			_box(visual, Vector3(0.15, 0.09, 0.06), Vector3(0, 1.76, 0.1),
				_mat(hair_c))

	# casco de scrum en la primera línea
	if index < 3:
		var cap := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 0.16
		cm.height = 0.24
		cap.mesh = cm
		cap.material_override = trim_mat
		cap.position = Vector3(0.0, 1.94, 0.0)
		visual.add_child(cap)

	var num := Label3D.new()
	num.text = str(index + 1)
	num.font_size = 80
	num.pixel_size = 0.0045
	num.modulate = trim
	num.outline_size = 8
	num.outline_modulate = Color(0.9, 0.9, 0.9) if jersey.get_luminance() < 0.4 \
		else Color(0.08, 0.08, 0.08)
	num.rotation.y = PI
	num.position = Vector3(0.0, 1.44, -0.17 * bulk)
	visual.add_child(num)

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
	if sin_bin_t > 0.0:
		sin_bin_t -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity_move(delta)
		_update_visual(delta, 0.0)
		return
	cool_pass = maxf(0.0, cool_pass - delta)
	cool_fend = maxf(0.0, cool_fend - delta)
	cool_kick = maxf(0.0, cool_kick - delta)
	dive_cd = maxf(0.0, dive_cd - delta)
	kick_anim_t = maxf(0.0, kick_anim_t - delta)
	froze_t = maxf(0.0, froze_t - delta)
	step_cd = maxf(0.0, step_cd - delta)
	if tackled > 0.0:
		if self == game.controlled and game.offloader == self \
				and Input.is_action_just_pressed("pass"):
			game.on_offload(self)
		tackled -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity_move(delta)
		_update_visual(delta, 0.0)
		return

	# congelado por el amague: no te podés mover ni placar
	if froze_t > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_gravity_move(delta)
		_update_visual(delta, 0.0)
		return
	# pick and go: el forward carga hacia adelante unos metros
	if surge_t > 0.0:
		surge_t -= delta
	if pass_anim_t > 0.0:
		pass_anim_t -= delta
		var sd := Vector3(0.0, 0.0, float(game.attack_dir[team]))
		velocity.x = sd.x * 8.5
		velocity.z = sd.z * 8.5
		facing = sd
		_apply_gravity_move(delta)
		_update_visual(delta, 8.5)
		return
	# sidestep: burst lateral rapido que dificulta placarte
	if step_t > 0.0:
		step_t -= delta
		velocity.x = step_dir.x * 12.5
		velocity.z = step_dir.z * 12.5
		_apply_gravity_move(delta)
		_update_visual(delta, 11.0)
		_try_pickup()
		return
	# lance de placaje: el cuerpo se tira, alcance mayor, si erras caes
	if dive_t > 0.0:
		dive_t -= delta
		velocity.x = dive_dir.x * 11.0
		velocity.z = dive_dir.z * 11.0
		_apply_gravity_move(delta)
		_update_visual(delta, 9.0)
		_try_tackle()
		if dive_t <= 0.0:
			tackled = 0.75               # recuperacion en el suelo
		return

	var wish := _desired_velocity()
	# fatiga: correr fuerte gasta, trotar recupera
	var run := Vector2(wish.x, wish.z).length()
	if run > 8.0:
		stamina = clampf(stamina - delta * 0.07, 0.0, 1.0)
	else:
		stamina = clampf(stamina + delta * 0.05, 0.0, 1.0)
	wish *= 0.7 + 0.3 * stamina
	velocity.x = wish.x
	velocity.z = wish.z

	# separación suave: los jugadores no se superponen, sin física dura
	for op in game.players:
		if op == self or op.tackled > 0.0:
			continue
		var diff := global_position - op.global_position
		diff.y = 0.0
		var dd := diff.length()
		if dd < 1.05 and dd > 0.001:
			var push := diff.normalized() * ((1.05 - dd) / 1.05) * 7.5
			velocity.x += push.x
			velocity.z += push.z
	_apply_gravity_move(delta)

	var hs := Vector2(velocity.x, velocity.z).length()
	if hs > 0.4:
		facing = facing.lerp(Vector3(velocity.x, 0.0, velocity.z).normalized(),
			delta * 10.0).normalized()
	_update_visual(delta, hs)
	if game.ball != null and game.ball.carrier == self:
		stat_metros += hs * delta
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
		RugbyGame.Phase.MAUL:
			return _maul_ai()
		RugbyGame.Phase.PENALTY:
			return _penalty_ai()
		_:
			return Vector3.ZERO
	if game.controlled == self:
		var iv := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var d := game.cam_move_dir(iv)
		if game.opt_sprint_toggle and Input.is_action_just_pressed("sprint"):
			sprint_on = not sprint_on
		var sprinting: bool = sprint_on if game.opt_sprint_toggle \
			else Input.is_action_pressed("sprint")
		var sp := (SPRINT_SPEED if sprinting else BASE_SPEED) \
			* speed_mult
		if game.ball.carrier == self:
			if Input.is_action_just_pressed("pass"):
				_do_pass(0)
			if Input.is_action_just_pressed("pass_left"):
				_do_pass(-1)
			if Input.is_action_just_pressed("pass_right"):
				_do_pass(1)
			if Input.is_action_just_pressed("kick"):
				_do_kick()
			if Input.is_action_just_pressed("dropgoal"):
				_do_drop_goal()
			if Input.is_action_just_pressed("grubber"):
				_do_grubber()
			if Input.is_action_just_pressed("bomb"):
				_do_bomb()
			if Input.is_action_just_pressed("crosskick"):
				_do_crosskick()
			if Input.is_action_just_pressed("step") and step_cd <= 0.0:
				_start_step()
			if Input.is_action_just_pressed("dummy"):
				_do_dummy()
			if Input.is_action_just_pressed("fend") and cool_fend <= 0.0:
				_do_fend()
		elif Input.is_action_just_pressed("tackle") and dive_cd <= 0.0:
			var c := game.ball.carrier
			var dir := facing
			if c != null and c.team != team:
				var to := c.global_position - global_position
				to.y = 0.0
				if to.length() > 0.1:
					dir = to.normalized()
			_start_dive(dir)
		return d * sp
	return _ai_velocity()


func _ai_velocity() -> Vector3:
	var b := game.ball
	if game.phase == RugbyGame.Phase.BREAKDOWN:
		return _ruck_ai()
	var ai_speed := AI_CHASE * rating * speed_mult
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


func _maul_ai() -> Vector3:
	var c := game.ball.carrier
	if c == null:
		return Vector3.ZERO
	var d := game.maul_dir
	if team == game.maul_team:
		if c == self:
			return Vector3.ZERO        # al portador lo mueve el juego
		if is_forward() and _team_rank(c.global_position) < 5:
			return _seek(c.global_position -
				Vector3((index % 3) - 1.0, 0.0, d * (1.0 + index % 2)), AI_JOG)
		return _hold()
	# los forwards rivales presionan el maul de frente
	if is_forward() and _team_rank(c.global_position) < 3:
		return _seek(c.global_position + Vector3(0.0, 0.0, d * 1.2), AI_JOG)
	return _hold()


func _penalty_ai() -> Vector3:
	# los defensores retroceden 10m respetando el penal
	if team != game.pending_team:
		var d := float(game.attack_dir[game.pending_team])
		var t := game.pending_spot - Vector3(0.0, 0.0, d * 10.0)
		t.x = global_position.x * 0.6
		return _seek(t, AI_JOG)
	if is_nine():
		return _seek(game.pending_spot, AI_CHASE)
	return _hold()


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

	if nearest_d < 1.9 and cool_pass <= 0.0:
		var offload := game.find_pass_target(self, true)
		if offload != null and game.rng.randf() < 0.6:
			game.ball.throw_to(offload, self)
			cool_pass = 1.4
			return Vector3.ZERO

	if cool_kick <= 0.0 and global_position.z * d < -28.0 and game.rng.randf() < 0.02:
		cool_kick = 4.0
		var kdir := Vector3(-global_position.x * 0.012, 0.0, d).normalized()
		game.ball.kicked(self, kdir)
		return Vector3.ZERO

	if nearest_d < 2.8 and cool_pass <= 0.0:
		var target := game.find_pass_target(self, true)
		if target != null:
			game.ball.throw_to(target, self)
			cool_pass = 1.1
			return Vector3.ZERO

	if nearest_d > 2.0 and nearest_d < 4.5 and step_cd <= 0.0 \
			and game.rng.randf() < 0.06:
		_start_step()
	if cool_kick <= 0.0 and global_position.z * d > 14.0 \
			and global_position.z * d < 32.0 and game.rng.randf() < 0.008:
		_do_grubber()
		return Vector3.ZERO
	if cool_kick <= 0.0 and global_position.z * d > 26.0 \
			and game.rng.randf() < 0.006:
		_do_bomb()
		return Vector3.ZERO
	if nearest_d < 5.5:
		var evade := side * (1.0 if side.dot(nearest_rel) < 0.0 else -1.0)
		if (left < right) != (evade.dot(side) > 0.0):
			evade = -evade
		dir = (dir * 0.55 + evade * 0.85).normalized()

	if is_nine() and cool_kick <= 0.0 and game.rng.randf() < 0.012:
		_do_box_kick()
		return Vector3.ZERO
	if nearest_d > 6.0 and game.drop_goal_team < 0 \
			and global_position.z * d > 8.0 and game.rng.randf() < 0.002:
		_do_drop_goal()
		return Vector3.ZERO

	return dir * AI_CHASE * 1.06 * rating * speed_mult


func _support_ai() -> Vector3:
	var c := game.ball.carrier
	var d := float(game.attack_dir[team])
	var cp := c.global_position
	# el 9 siempre pegado a la jugada, listo para servir la pelota
	if is_nine():
		return _seek(cp - Vector3(0.0, 0.0, d * 2.2), AI_CHASE * speed_mult)
	# lado abierto: el de mas cancha por delante
	# lado ancho con memoria: solo cambia cuando el balón cruza bien el centro
	if absf(cp.x) > 8.0:
		wide_mem = -signf(cp.x)
	if is_forward():
		# pods a ambos lados del breakdown, como un pack real reagrupando
		var pod := index / 3                 # 0:front row, 1:segundas+8, 2:flankers
		var in_pod := index % 3
		var pdir := wide_mem if pod % 2 == 0 else -wide_mem
		var px := clampf(cp.x + pdir * (4.5 + pod * 5.5) +
			(in_pod - 1.0) * 1.9, -31.0, 31.0)
		var pz := cp.z - d * (1.5 + pod * 1.4)
		return _seek(Vector3(px, 0.0, pz), AI_JOG * 1.15 * speed_mult)
	if index >= 9 and index <= 13:
		# línea de backs: 10 profundo; unos al lado ancho, otros al cerrado
		var order := index - 9               # 10->0 ... 14->4
		var bdir := wide_mem if order < 3 else -wide_mem
		var slot := order if order < 3 else order - 3
		var bx := clampf(cp.x + bdir * (5.0 + slot * 5.5), -31.0, 31.0)
		var bz := cp.z - d * (6.0 - slot * 0.6)
		return _seek(Vector3(bx, 0.0, bz), AI_JOG * speed_mult)
	# fullback: cobertura profunda detras de la jugada
	return _seek(Vector3(cp.x * 0.4, 0.0, cp.z - d * 15.0), AI_JOG * speed_mult)


func _defense_ai() -> Vector3:
	var c := game.ball.carrier
	var cdir := float(game.attack_dir[c.team])
	var rank := _team_rank(c.global_position)
	var dist_c := global_position.distance_to(c.global_position)
	# el defensor mas cercano se lanza si llega con ventaja
	if rank == 0 and dive_cd <= 0.0 and dist_c > 2.3 and dist_c < 5.2:
		var dd := (c.global_position - global_position)
		dd.y = 0.0
		_start_dive(dd.normalized())
		return dive_dir * 11.0
	# presion: los dos mas cerca van al portador
	if rank < 3:
		return _seek(c.global_position, AI_CHASE * 1.08 * rating * speed_mult)
	var offside_z := c.global_position.z - cdir * 1.4
	# guards del ruck: forwards cubriendo los bordes del breakdown
	if is_forward() and rank < 5:
		var gx := clampf(c.global_position.x +
			signf(global_position.x - c.global_position.x + 0.01) * 5.5,
			-30.0, 30.0)
		return _seek(Vector3(gx, 0.0, offside_z), AI_JOG * speed_mult)
	# fullback: cobertura profunda para las patadas
	if index == 14:
		return _seek(Vector3(c.global_position.x * 0.5, 0.0,
			clampf(c.global_position.z - cdir * 20.0, -54.0, 54.0)),
			AI_JOG * speed_mult)
	# linea defensiva chata sobre el offside, corriendose hacia el balon
	var lane := lerpf(-30.0, 30.0, index / 14.0)
	lane = clampf(lane + c.global_position.x * 0.35, -31.0, 31.0)
	return _seek(Vector3(lane, 0.0, offside_z - cdir * 0.6),
		AI_JOG * rating * speed_mult)


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
		if b.pass_from != null and b.pass_from.team != team:
			# intercepcion: el defensor puede atrapar el pase en el aire
			var ic := 0.05 if self == game.controlled else 0.028
			if game.rng.randf() < ic:
				b.set_carrier(self)
				game.ui.flash_hint("¡¡INTERCEPCIÓN de %s!!" % game._club_name(team))
				game.ui.commentary("¡Lee el pase y sale disparado!")
			return
		if b.pass_from != null and b.pass_from.team == team and self != game.controlled:
			var chance := 0.1 if b.pass_from != game.controlled else 0.04
			if game.weather == "rain":
				chance *= 1.8      # pelota mojada
			if game.rng.randf() < chance:
				game.on_knock_on(self)
				return
		# ¿marca? hay que evaluarla antes de set_carrier que resetea los flags
		var is_mark := b.was_kicked and b.last_touch_team != team and \
			global_position.z * float(game.attack_dir[team]) < -28.0
		b.set_carrier(self)
		if is_mark:
			game.on_mark(self)


func _try_tackle() -> void:
	if froze_t > 0.0:
		return
	var c := game.ball.carrier
	if c == null or c.team == team or c.tackled > 0.0:
		return
	if game.phase != RugbyGame.Phase.PLAY:
		return
	var reach := RugbyGame.TACKLE_RANGE * (1.0 if game.controlled != self else 1.25)
	if dive_t > 0.0:
		reach = 2.1
	if c.step_t > 0.0:
		reach *= 0.5
	if global_position.distance_to(c.global_position) < reach:
		if game.rng.randf() < c.break_prob:
			tackled = 0.8
			game.ui.flash_hint("¡ROMPIÓ EL PLACAJE!")
			return
		game.on_tackle(self, c)


func _start_dive(dir: Vector3) -> void:
	if tackled > 0.0 or sin_bin_t > 0.0 or dive_t > 0.0 or dive_cd > 0.0:
		return
	dive_dir = dir
	dive_dir.y = 0.0
	if dive_dir.length() < 0.1:
		dive_dir = facing
	dive_dir = dive_dir.normalized()
	dive_t = 0.45
	dive_cd = 1.7
	facing = dive_dir


# side: -1 izquierda, +1 derecha, 0 automatico
func _do_pass(side := 0) -> void:
	var target: RugbyPlayer = null
	if side == 0:
		target = game.find_pass_target(self, true)
		if target == null:
			target = game.find_pass_target(self, false)
	else:
		target = game.find_pass_target_side(self, side)
	if target == null:
		game.ui.flash_hint("¡Sin apoyo de ese lado!" if side != 0 \
			else "¡Sin compañeros cerca!")
		return
	var fwd := (target.global_position.z - global_position.z) * float(game.attack_dir[team])
	if fwd > 0.4:
		game.on_forward_pass(self)
		return
	game.ball.throw_to(target, self)
	pass_anim_t = 0.3
	cool_pass = 0.4


func _do_kick() -> void:
	var d := float(game.attack_dir[team])
	var dir := Vector3(-global_position.x * 0.015, 0.0, d).normalized()
	game.ball.kicked(self, dir)

# dummy pass: amague que congela a los defensores cercanos medio segundo
func _do_dummy() -> void:
	var n := 0
	for p in game.players:
		if p.team == team or p.tackled > 0.0:
			continue
		if p.global_position.distance_to(global_position) < 4.5:
			p.froze_t = 0.5
			n += 1
	if n > 0:
		game.ui.flash_hint("¡AMAGUE! %d defensores picaron" % n)
	cool_pass = 0.35


func _do_grubber() -> void:
	var d := float(game.attack_dir[team])
	var dir := Vector3(-global_position.x * 0.008, 0.0, d).normalized()
	game.ball.grubber(self, dir)
	cool_kick = 0.8


func _do_bomb() -> void:
	var d := float(game.attack_dir[team])
	var dir := Vector3(-global_position.x * 0.01, 0.0, d).normalized()
	game.ball.bomb(self, dir)
	cool_kick = 0.8


# cross kick: patada cruzada larga hacia el wing del lado opuesto
func _do_crosskick() -> void:
	var d := float(game.attack_dir[team])
	var wing_idx := 10 if global_position.x > 0.0 else 13
	var wing := game.players[wing_idx + team * RugbyGame.TEAM_SIZE]
	var target := Vector3(-signf(global_position.x) * 28.0, 0.0,
		wing.global_position.z + d * 6.0)
	var dir := (target - global_position)
	dir.y = 0.0
	game.ball.kicked(self, dir.normalized())
	cool_kick = 0.8


# box kick del 9: patada corta disputada por el costado tras el ruck
func _do_box_kick() -> void:
	var d := float(game.attack_dir[team])
	var side := signf(global_position.x)
	if side == 0.0:
		side = 1.0
	var dir := Vector3(side * 0.45, 0.0, d).normalized()
	game.ball.bomb(self, dir)
	cool_kick = 1.0


# sidestep: burst lateral hacia el lado con menos defensores
func _start_step(side := 0.0) -> void:
	if tackled > 0.0 or step_t > 0.0 or step_cd > 0.0:
		return
	var lat := Vector3(facing.z, 0.0, -facing.x)
	if self == game.controlled:
		var iv := Input.get_vector("move_left", "move_right",
			"move_up", "move_down")
		if absf(iv.x) > 0.3:
			var r3 := game.cam_move_dir(Vector2(signf(iv.x), 0.0))
			side = 1.0 if lat.dot(r3) > 0.0 else -1.0
	if side == 0.0:
		var left_n := 0
		var right_n := 0
		for p in game.players:
			if p.team == team or p.tackled > 0.0:
				continue
			var rel := p.global_position - global_position
			if rel.length() < 7.0:
				if lat.dot(rel) > 0.0:
					left_n += 1
				else:
					right_n += 1
		side = 1.0 if left_n <= right_n else -1.0
	step_dir = (lat * side).normalized()
	step_t = 0.28
	step_cd = 0.9
	facing = step_dir


func _do_drop_goal() -> void:
	var d := float(game.attack_dir[team])
	var posts := Vector3(0.0, 0.0, d * RugbyField.TRY)
	var dist := Vector2(posts.x - global_position.x,
		posts.z - global_position.z).length()
	if dist > 42.0:
		game.ui.flash_hint("¡Muy lejos para el drop!")
		return
	var from := carry_point()
	game.ball.release()
	game.ball.global_position = from
	var t := clampf(dist / 20.0, 0.9, 2.0)
	var v := Vector3(posts.x - from.x, 0.0, posts.z - from.z) / t
	v.y = (4.2 + 4.9 * t * t) / t
	game.ball.linear_velocity = v
	game.ball.angular_velocity = Vector3(-d, 0, 0) * 8.0
	game.ball.release_guard = 0.4
	game.ball.last_touch_team = team
	game.drop_goal_team = team
	game.drop_prev_z = from.z
	game.ui.flash_hint("¡DROP GOAL!")


func _do_fend() -> void:
	cool_fend = 3.0
	for p in game.players:
		if p.team == team or p.tackled > 0.0:
			continue
		var rel := p.global_position - global_position
		rel.y = 0.0
		if rel.length() < 2.3 and rel.normalized().dot(facing) > 0.25:
			p.tackled = 1.1
			game.ui.flash_hint("¡FEND!")
			return


func _update_visual(delta: float, h_speed: float) -> void:
	bob_t += delta * (4.0 + h_speed * 1.6)
	var run := clampf(h_speed / SPRINT_SPEED, 0.0, 1.0)
	if kick_anim_t > 0.0:
		var ks := 1.0 - kick_anim_t / 0.6      # 0→1 durante la patada
		leg_r.rotation.x = lerpf(leg_r.rotation.x,
			-1.5 if ks < 0.5 else 1.3, delta * 18.0)   # backswing → follow through
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.35, delta * 10.0)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -0.9, delta * 10.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.9, delta * 10.0)
		visual.rotation.x = lerpf(visual.rotation.x, 0.18, delta * 10.0)
		return
	if dive_t > 0.0:
		visual.rotation.x = lerpf(visual.rotation.x, -1.5, delta * 14.0)
		visual.position.y = lerpf(visual.position.y, 0.18, delta * 14.0)
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.9, delta * 10.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.4, delta * 10.0)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -2.2, delta * 12.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -2.2, delta * 12.0)
		return
	if tackled > 0.0:
		visual.rotation.x = lerpf(visual.rotation.x, -1.45, delta * 8.0)
		visual.position.y = lerpf(visual.position.y, 0.12, delta * 8.0)
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, delta * 6.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, delta * 6.0)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, delta * 6.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, delta * 6.0)
		return
	# salto en el lineout para los jumpers del equipo que tira
	var jump_y := 0.0
	if game.phase == RugbyGame.Phase.LINEOUT and game.phase_t < 1.0 \
			and team == game.pending_team and index in [2, 3, 6]:
		jump_y = sin((1.0 - game.phase_t) * PI) * 0.55
	# celebración de try: brazos arriba
	var celebra: bool = (game.celebrating == self and game.phase == RugbyGame.Phase.SCORE) or game.celebrate_all_team == team
	visual.rotation.x = lerpf(visual.rotation.x, run * 0.24, delta * 8.0)
	visual.position.y = lerpf(visual.position.y, jump_y, delta * 8.0) \
		+ absf(sin(bob_t)) * 0.06 * run + sin(bob_t * 0.31) * 0.01
	var swing := sin(bob_t) * (1.05 * run)
	leg_l.rotation.x = swing
	leg_r.rotation.x = -swing
	arm_l.rotation.x = -swing * 0.85
	arm_r.rotation.x = swing * 0.85
	if pass_anim_t > 0.0:                 # gesto del pase
		var pk := pass_anim_t / 0.3
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -1.9, pk)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.9, pk)
		visual.rotation.y += sin(pk * PI) * 0.12
	if game != null and game.ball != null and game.ball.carrier == self:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -0.85, delta * 10.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -0.85, delta * 10.0)
		arm_l.rotation.z = lerpf(arm_l.rotation.z, 0.5, delta * 10.0)
		arm_r.rotation.z = lerpf(arm_r.rotation.z, -0.5, delta * 10.0)
	if celebra:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -2.7, delta * 10.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -2.7, delta * 10.0)
	if h_speed > 0.4:
		visual.rotation.y = lerp_angle(visual.rotation.y,
			atan2(facing.x, facing.z), delta * 10.0)
	marker.position.y = 2.5 + sin(bob_t * 0.6) * 0.12
