extends Node3D
class_name RugbyField

# Construye todo el entorno visual: césped, líneas, postes, carteles y tribunas.
const W := 34.0
const TRY := 50.0
const DEAD := 58.0
const WHITE := Color(0.95, 0.95, 0.92)

static func build(parent: Node3D) -> RugbyField:
	var f := RugbyField.new()
	parent.add_child(f)
	f._build()
	return f


func _mat(c: Color, rough := 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _build() -> void:
	_build_env()
	_build_ground()
	_build_lines()
	_build_posts()
	_build_surroundings()


func _build_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.22, 0.42, 0.78)
	psm.sky_horizon_color = Color(0.62, 0.76, 0.9)
	psm.ground_bottom_color = Color(0.16, 0.26, 0.16)
	psm.ground_horizon_color = Color(0.55, 0.68, 0.7)
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 180.0
	sun.light_energy = 1.2
	add_child(sun)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(160.0, 1.0, 150.0)
	cs.shape = shape
	cs.position = Vector3(0.0, -0.5, 0.0)
	body.add_child(cs)

	# fajas de césped alternadas (efecto cortina de corte)
	var green_a := _mat(Color(0.16, 0.42, 0.16))
	var green_b := _mat(Color(0.2, 0.5, 0.2))
	for i in 15:
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(160.0, 0.06, 10.0)
		mi.mesh = mesh
		mi.material_override = green_a if i % 2 == 0 else green_b
		mi.position = Vector3(0.0, -0.02, -70.0 + i * 10.0 + 5.0)
		add_child(mi)

	# in-goal con tono más oscuro
	var ingoal := _mat(Color(0.13, 0.36, 0.18))
	for s in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(W * 2.0, 0.04, DEAD - TRY)
		mi.mesh = mesh
		mi.material_override = ingoal
		mi.position = Vector3(0.0, 0.01, s * (TRY + (DEAD - TRY) * 0.5))
		add_child(mi)


func _line(x1: float, z1: float, x2: float, z2: float, w := 0.18) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	var dx := x2 - x1
	var dz := z2 - z1
	m.size = Vector3(Vector2(dx, dz).length(), 0.05, w)
	mi.mesh = m
	mi.material_override = _mat(WHITE)
	mi.position = Vector3((x1 + x2) * 0.5, 0.03, (z1 + z2) * 0.5)
	mi.rotation.y = -atan2(dz, dx)
	add_child(mi)


func _dash_line(x1: float, z1: float, x2: float, z2: float, dash := 1.6, gap := 1.6) -> void:
	var total := Vector2(x2 - x1, z2 - z1).length()
	var dir := Vector2(x2 - x1, z2 - z1).normalized()
	var t := 0.0
	while t < total:
		var a := Vector2(x1, z1) + dir * t
		var b := Vector2(x1, z1) + dir * minf(t + dash, total)
		_line(a.x, a.y, b.x, b.y, 0.14)
		t += dash + gap


func _build_lines() -> void:
	# líneas de touch (laterales) y pelota muerta
	for s in [-1.0, 1.0]:
		_line(s * W, -TRY, s * W, TRY)
		_line(-W, s * DEAD, W, s * DEAD)
		# línea de gol / try
		_line(-W, s * TRY, W, s * TRY, 0.24)
		# línea de 22m (a 28 del centro)
		_line(-W, s * 28.0, W, s * 28.0)
		# 10m punteada
		_dash_line(-W, s * 10.0, W, s * 10.0)
		# 5m punteada junto a cada touch
		_dash_line(s * (W - 5.0), -TRY, s * (W - 5.0), TRY, 1.2, 1.8)
	# mitad de cancha
	_line(-W, 0.0, W, 0.0, 0.24)
	# marcas de 15m
	for s in [-1.0, 1.0]:
		var x: float = s * (W - 15.0)
		var z := -45.0
		while z <= 45.0:
			_line(x, z, x, z + 1.0, 0.14)
			z += 5.0


func _build_posts() -> void:
	var post_mat := _mat(WHITE, 0.6)
	for s in [-1.0, 1.0]:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = Vector3(0.0, 0.0, s * TRY)
		add_child(body)
		for px in [-2.8, 2.8]:
			var upright := MeshInstance3D.new()
			var m := CylinderMesh.new()
			m.top_radius = 0.09
			m.bottom_radius = 0.09
			m.height = 8.0
			upright.mesh = m
			upright.material_override = post_mat
			upright.position = Vector3(px, 4.0, 0.0)
			body.add_child(upright)
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.12
			cyl.height = 8.0
			cs.shape = cyl
			cs.position = Vector3(px, 4.0, 0.0)
			body.add_child(cs)
		var bar := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.09
		bm.bottom_radius = 0.09
		bm.height = 5.8
		bar.mesh = bm
		bar.material_override = post_mat
		bar.rotation.z = PI / 2.0
		bar.position = Vector3(0.0, 3.0, 0.0)
		body.add_child(bar)


func _build_surroundings() -> void:
	# vallas publicitarias bajas alrededor de la cancha
	var ad := _mat(Color(0.9, 0.9, 0.95), 0.7)
	for s in [-1.0, 1.0]:
		_add_box(Vector3(0, 0.45, s * (DEAD + 4.0)), Vector3(76.0, 0.9, 0.4), ad)
		_add_box(Vector3(s * (W + 4.0), 0.45, 0), Vector3(0.4, 0.9, 118.0), ad)

	# tribunas simples (lejos, no bloquean la cámara que está en -X)
	var stand_mat := _mat(Color(0.25, 0.27, 0.32), 0.85)
	var seat_mat := _mat(Color(0.7, 0.15, 0.15), 0.85)
	_add_box(Vector3(52.0, 5.0, 0), Vector3(14.0, 10.0, 120.0), stand_mat)
	_add_box(Vector3(50.0, 10.5, 0), Vector3(10.0, 1.0, 116.0), seat_mat)
	for s in [-1.0, 1.0]:
		_add_box(Vector3(0, 5.0, s * 72.0), Vector3(110.0, 10.0, 14.0), stand_mat)
		_add_box(Vector3(0, 10.5, s * 70.0), Vector3(106.0, 1.0, 10.0), seat_mat)


func _add_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
