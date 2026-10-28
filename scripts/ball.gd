extends RigidBody3D
class_name RugbyBall

var game: RugbyGame
var carrier: RugbyPlayer = null
var release_guard := 0.0
var last_touch_team := -1
var pass_from: RugbyPlayer = null   # usado para knock-on en la recepción
var was_kicked := false            # viene de una patada (para la marca)
var kick_origin_z := 0.0           # dónde se pateó (para la regla del 50/22)


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	mass = 0.45
	continuous_cd = true
	linear_damp = 0.1
	angular_damp = 0.7
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.5
	pm.friction = 0.9
	physics_material_override = pm

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.17
	cap.height = 0.44
	cs.shape = cap
	cs.rotation.x = PI / 2.0
	add_child(cs)

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.36
	mi.mesh = sm
	mi.rotation.x = PI / 2.0
	mi.scale.y = 1.5            # alargada: forma de pelota de rugby
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _leather_tex()
	mat.roughness = 0.62
	mat.metallic_specular = 0.4
	mi.material_override = mat
	add_child(mi)

	# costura alrededor de la panza (toro oscuro) + aro claro de panel
	# (la textura de cuero con paneles y cordones la arma _leather_tex)
	var seam := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.14
	tm.outer_radius = 0.185
	seam.mesh = tm
	seam.rotation.x = PI / 2.0
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.28, 0.15, 0.07)
	smat.roughness = 0.8
	seam.material_override = smat
	add_child(seam)

	var ring := MeshInstance3D.new()
	var tm2 := TorusMesh.new()
	tm2.inner_radius = 0.148
	tm2.outer_radius = 0.172
	ring.mesh = tm2
	ring.rotation.x = PI / 2.0
	ring.position.z = 0.05
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.92, 0.9, 0.85)
	rmat.roughness = 0.75
	ring.material_override = rmat
	add_child(ring)
	freeze = true


func _physics_process(delta: float) -> void:
	if release_guard > 0.0:
		release_guard -= delta
	if carrier != null:
		global_position = carrier.carry_point()


func can_pickup() -> bool:
	return carrier == null and release_guard <= 0.0


func set_carrier(p: RugbyPlayer) -> void:
	release()
	carrier = p
	pass_from = null
	was_kicked = false
	last_touch_team = p.team
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func release() -> void:
	if carrier != null:
		last_touch_team = carrier.team
	carrier = null
	freeze = false
	sleeping = false


func throw_to(target: RugbyPlayer, thrower: RugbyPlayer) -> void:
	release()
	release_guard = 0.2
	last_touch_team = thrower.team
	pass_from = thrower
	was_kicked = false
	global_position = thrower.carry_point()
	var aim: Vector3 = target.global_position + target.velocity * 0.3 + Vector3(0, 0.9, 0) - global_position
	var flat := Vector2(aim.x, aim.z).length()
	var t := clampf(flat / 16.0, 0.22, 0.95)
	linear_velocity = Vector3(aim.x / t, (aim.y + 4.9 * t * t) / t + 0.5, aim.z / t)
	angular_velocity = linear_velocity.normalized() * 18.0



func grubber(kicker: RugbyPlayer, dir: Vector3) -> void:
	release()
	release_guard = 0.25
	last_touch_team = kicker.team
	pass_from = null
	was_kicked = true
	kick_origin_z = kicker.global_position.z
	global_position = kicker.carry_point()
	linear_velocity = dir * 15.0 + Vector3(0, 1.4, 0)
	angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 22.0
	game._mark_kick_offside(kicker)


func bomb(kicker: RugbyPlayer, dir: Vector3) -> void:
	release()
	release_guard = 0.35
	last_touch_team = kicker.team
	pass_from = null
	was_kicked = true
	kick_origin_z = kicker.global_position.z
	global_position = kicker.carry_point()
	linear_velocity = dir * 8.0 + Vector3(0, 14.5, 0)
	angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 16.0
	game._mark_kick_offside(kicker)


# chip kick: patadita corta por encima del defensor, a re-agrupar ~12m
func chip(kicker: RugbyPlayer, dir: Vector3) -> void:
	release()
	release_guard = 0.2
	last_touch_team = kicker.team
	pass_from = null
	was_kicked = true
	kick_origin_z = kicker.global_position.z
	global_position = kicker.carry_point()
	linear_velocity = dir * 8.5 + Vector3(0, 7.0, 0)
	angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 18.0
	game._mark_kick_offside(kicker)

func kicked(kicker: RugbyPlayer, dir: Vector3) -> void:
	release()
	release_guard = 0.3
	last_touch_team = kicker.team
	pass_from = null
	was_kicked = true
	kick_origin_z = kicker.global_position.z
	global_position = kicker.carry_point()
	linear_velocity = dir * 21.0 + Vector3(0, 8.5, 0)
	angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 14.0
	game._mark_kick_offside(kicker)


# cuero 2048 con grano por ruido nativo, costuras y cordones
static var _leather: Texture2D = null
static func _leather_tex() -> Texture2D:
	if _leather != null:
		return _leather
	const W := 2048
	const H := 1024
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var base := Color(0.58, 0.34, 0.16)
	img.fill(base)
	# grano de cuero: ruido nativo mezclado sutil
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.frequency = 0.35
	n.fractal_octaves = 4
	var nimg := n.get_image(W, H)
	for y in H:                        # convierto el gris en modulación sutil
		for x in W:
			var g := nimg.get_pixel(x, y).r - 0.5
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + g * 0.09, c.g + g * 0.09,
				c.b + g * 0.09))
	var seam := Color(0.3, 0.16, 0.07)
	for sx in [W / 4, W / 2, 3 * W / 4]:      # costuras de los 4 paneles
		img.fill_rect(Rect2i(sx - 2, 0, 5, H), seam)
	for y in range(int(H * 0.3), int(H * 0.72), int(H / 14)):
		img.fill_rect(Rect2i(W / 2 - 8, y, 17, 3), Color(0.93, 0.9, 0.85))
	_leather = ImageTexture.create_from_image(img)
	return _leather
