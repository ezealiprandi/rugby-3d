extends Node3D
class_name RugbyField

# Construye todo el entorno visual: césped, líneas, postes, tribunas con público,
# torres de luz, banderines de esquina, protectores de postes, bancos y carteles.
const W := 35.0
const TRY := 50.0
const DEAD := 60.0
const WHITE := Color(0.95, 0.95, 0.92)

var env_node: WorldEnvironment
var sun_node: DirectionalLight3D
var rain: GPUParticles3D
var floodlights: Array = []          # SpotLight3D de cada torre (noche)
var crowd_mm: MultiMesh = null       # hinchada (para teñir de colores del club)
var crowd_palette: Array = []
var crowd_pos: Array[Vector3] = []   # posiciones base para la ola
var flag_mats: Array = []            # banderas (se tiñen por partido)
var screen_mats: Array = []          # pantallas gigantes del estadio
var wave_t := 0.0
var wave_amp := 0.0                  # sube a 1.0 en un try

static func build(parent: Node3D) -> RugbyField:
	var f := RugbyField.new()
	parent.add_child(f)
	f._build()
	return f


static var _noise_tex: Texture2D = null
static func _noise() -> Texture2D:
	if _noise_tex == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.1
		var nt := NoiseTexture2D.new()
		nt.width = 256
		nt.height = 256
		nt.seamless = true
		nt.noise = n
		_noise_tex = nt
	return _noise_tex


# tex=true multiplica por un ruido gris (cemento/techo real) — se compensa el color
func _mat(c: Color, rough := 0.95, tex := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c * 1.7 if tex else c
	m.roughness = rough
	if tex:
		m.albedo_texture = RugbyField._noise()
		m.uv1_scale = Vector3(5.0, 5.0, 5.0)
	return m


func _build() -> void:
	_build_env()
	_build_ground()
	_build_lines()
	_build_posts()
	_build_surroundings()
	_build_floodlights()
	_build_crowd()
	_build_flags()
	_build_screens()
	_build_photographers()


func _build_env() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.16, 0.3, 0.62)          # tarde-noche
	psm.sky_horizon_color = Color(0.75, 0.62, 0.5)
	psm.ground_bottom_color = Color(0.1, 0.16, 0.1)
	psm.ground_horizon_color = Color(0.45, 0.5, 0.5)
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	# Forward+: tonemapping, bloom (solo los faros emisivos), SSAO, niebla sutil
	env.set("tonemap_mode", 2)   # 2 = filmic
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.25
	env.ssao_enabled = true
	env.ssao_radius = 2.0
	env.ssao_intensity = 1.6
	env.fog_enabled = true
	env.fog_density = 0.0035
	env.fog_light_color = Color(0.75, 0.68, 0.6)
	env.fog_light_energy = 0.5
	we.environment = env
	env_node = we
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -25.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 190.0
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.92, 0.8)             # luz cálida de atardecer
	sun_node = sun
	add_child(sun)


# clima: lluvia oscurece el cielo, baja el sol y agrega partículas
func set_weather(is_rain: bool) -> void:
	if env_node != null:
		env_node.environment.fog_density = 0.009 if is_rain else 0.0035
		var psm := env_node.environment.sky.sky_material as ProceduralSkyMaterial
		if psm != null:
			psm.sky_top_color = Color(0.28, 0.3, 0.34) if is_rain \
				else Color(0.16, 0.3, 0.62)
			psm.sky_horizon_color = Color(0.45, 0.47, 0.5) if is_rain \
				else Color(0.75, 0.62, 0.5)
	if sun_node != null:
		sun_node.light_energy = 0.55 if is_rain else 1.1
	if is_rain:
		if rain == null:
			_make_rain()
		rain.emitting = true
	elif rain != null:
		rain.emitting = false


func _make_rain() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 2500
	rain.lifetime = 1.1
	rain.visibility_aabb = AABB(Vector3(-60, -5, -70), Vector3(120, 40, 140))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(58.0, 1.0, 68.0)
	pm.direction = Vector3(0.12, -1.0, 0.0)
	pm.initial_velocity_min = 22.0
	pm.initial_velocity_max = 26.0
	pm.gravity = Vector3.ZERO
	rain.process_material = pm
	rain.position = Vector3(0.0, 24.0, 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.04, 0.7)
	var rain_mat := StandardMaterial3D.new()
	rain_mat.albedo_color = Color(0.7, 0.78, 0.85, 0.45)
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = rain_mat
	rain.draw_pass_1 = quad
	add_child(rain)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(180.0, 1.0, 170.0)
	cs.shape = shape
	cs.position = Vector3(0.0, -0.5, 0.0)
	body.add_child(cs)

	# fajas de césped alternadas con shader: variación de tono por parche
	var grass_shader := Shader.new()
	grass_shader.code = """
shader_type spatial;
uniform vec4 color : source_color;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 u = fract(p);
	u = u * u * (3.0 - 2.0 * u);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	float patch = vnoise(VERTEX.xz * 0.22);          // manchones grandes
	float mid = vnoise(VERTEX.xz * 1.7);             // variación media
	float grain = vnoise(VERTEX.xz * 14.0);          // textura de pasto fino
	float mow = step(0.5, fract(VERTEX.x * 0.35)) * 0.05;   // líneas de corte
	ALBEDO = color.rgb * (0.72 + patch * 0.18 + mid * 0.12
		+ grain * 0.10 + mow);
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
}
"""
	var green_a := ShaderMaterial.new()
	green_a.shader = grass_shader
	green_a.set_shader_parameter("color", Color(0.15, 0.4, 0.15))
	var green_b := ShaderMaterial.new()
	green_b.shader = grass_shader
	green_b.set_shader_parameter("color", Color(0.19, 0.48, 0.19))
	for i in 17:
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(180.0, 0.06, 10.0)
		mi.mesh = mesh
		mi.material_override = green_a if i % 2 == 0 else green_b
		mi.position = Vector3(0.0, -0.02, -80.0 + i * 10.0 + 5.0)
		add_child(mi)

	# in-goal con tono más oscuro (altura distinta a todo lo demás: sin z-fighting)
	var ingoal := _mat(Color(0.12, 0.34, 0.17))
	for s in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(W * 2.0, 0.014, DEAD - TRY)
		mi.mesh = mesh
		mi.material_override = ingoal
		mi.position = Vector3(0.0, 0.02, s * (TRY + (DEAD - TRY) * 0.5))
		add_child(mi)


func _line(x1: float, z1: float, x2: float, z2: float, w := 0.18) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	var dx := x2 - x1
	var dz := z2 - z1
	m.size = Vector3(Vector2(dx, dz).length(), 0.05, w)
	mi.mesh = m
	mi.material_override = _mat(WHITE)
	mi.position = Vector3((x1 + x2) * 0.5, 0.055, (z1 + z2) * 0.5)
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
	for s in [-1.0, 1.0]:
		_line(s * W, -TRY, s * W, TRY)                 # touchlines
		_line(-W, s * DEAD, W, s * DEAD)               # pelota muerta
		_line(-W, s * TRY, W, s * TRY, 0.28)           # línea de try
		_line(-W, s * 28.0, W, s * 28.0)               # 22m
		_dash_line(-W, s * 10.0, W, s * 10.0)          # 10m
		_dash_line(s * (W - 5.0), -TRY, s * (W - 5.0), TRY, 1.2, 1.8)   # 5m
	_line(-W, 0.0, W, 0.0, 0.28)                       # mitad de cancha
	# marcas de 15m
	for s in [-1.0, 1.0]:
		var x: float = s * (W - 15.0)
		var z := -45.0
		while z <= 45.0:
			_line(x, z, x, z + 1.0, 0.14)
			z += 5.0

	# banderines de esquina (en la unión touch/try)
	var flag_mat := _mat(Color(1.0, 0.55, 0.1))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pole := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.03
			pm.bottom_radius = 0.03
			pm.height = 1.4
			pole.mesh = pm
			pole.material_override = flag_mat
			pole.position = Vector3(sx * W, 0.7, sz * TRY)
			add_child(pole)
			var flag := MeshInstance3D.new()
			var fm := BoxMesh.new()
			fm.size = Vector3(0.35, 0.22, 0.02)
			flag.mesh = fm
			flag.material_override = _mat(Color(0.95, 0.1, 0.1))
			flag.position = Vector3(sx * W - 0.18, 1.28, sz * TRY)
			add_child(flag)


func _build_posts() -> void:
	var post_mat := _mat(WHITE, 0.55)
	var pad_mat := _mat(Color(0.1, 0.2, 0.55), 0.9)
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
			m.height = 9.0
			upright.mesh = m
			upright.material_override = post_mat
			upright.position = Vector3(px, 4.5, 0.0)
			body.add_child(upright)
			var cs := CollisionShape3D.new()
			var cyl := CylinderShape3D.new()
			cyl.radius = 0.13
			cyl.height = 9.0
			cs.shape = cyl
			cs.position = Vector3(px, 4.5, 0.0)
			body.add_child(cs)
			# protector de poste
			var pad := MeshInstance3D.new()
			var pdm := BoxMesh.new()
			pdm.size = Vector3(0.6, 1.2, 0.6)
			pad.mesh = pdm
			pad.material_override = pad_mat
			pad.position = Vector3(px, 0.6, 0.0)
			body.add_child(pad)
		# travesaño con colisión real (el balón puede pegar y rebotar)
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
		var bcs := CollisionShape3D.new()
		var bcyl := CylinderShape3D.new()
		bcyl.radius = 0.1
		bcyl.height = 5.8
		bcs.shape = bcyl
		bcs.rotation.z = PI / 2.0
		bcs.position = Vector3(0.0, 3.0, 0.0)
		body.add_child(bcs)


func _add_box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _ad_mat(c1: Color, c2: Color) -> StandardMaterial3D:
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 128:
			img.set_pixel(x, y, c1 if int((x + y * 2) / 16) % 2 == 0 else c2)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 0.7
	return m


func _build_surroundings() -> void:
	# vallas publicitarias alternadas alrededor de la cancha
	var ads := [
		_ad_mat(Color(0.92, 0.92, 0.95), Color(0.55, 0.55, 0.6)),
		_ad_mat(Color(0.12, 0.2, 0.5), Color(0.9, 0.9, 0.95)),
		_ad_mat(Color(0.85, 0.1, 0.1), Color(0.95, 0.95, 0.9)),
		_ad_mat(Color(0.95, 0.7, 0.1), Color(0.15, 0.15, 0.15))]
	var ai := 0
	for s in [-1.0, 1.0]:
		var x := -32.0
		while x < 32.0:
			_add_box(Vector3(x + 4.0, 0.45, s * (DEAD + 3.5)), Vector3(8.0, 0.9, 0.35), ads[ai % 4])
			x += 8.0
			ai += 1
		var z := -55.0
		while z < 55.0:
			_add_box(Vector3(s * (W + 3.5), 0.45, z + 4.0), Vector3(0.35, 0.9, 8.0), ads[ai % 4])
			z += 8.0
			ai += 1

	# tribunas con gradas escalonadas
	var concrete := _mat(Color(0.32, 0.33, 0.36), 0.95, true)
	var roof := _mat(Color(0.2, 0.22, 0.28), 0.8, true)
	# tribuna principal (lado +X, opuesto a la cámara) con techo
	for i in 6:
		_add_box(Vector3(46.0 + i * 3.0, 1.2 + i * 1.6, 0),
			Vector3(3.0, 2.4 + i * 0.4, 130.0), concrete)
	_add_box(Vector3(66.0, 15.0, 0), Vector3(8.0, 12.0, 130.0), concrete)
	_add_box(Vector3(62.0, 21.5, 0), Vector3(22.0, 1.2, 132.0), roof)   # techo
	# tribunas de fondo
	for s in [-1.0, 1.0]:
		for i in 5:
			_add_box(Vector3(0.0, 1.2 + i * 1.6, s * (70.0 + i * 3.0)),
				Vector3(120.0, 2.4 + i * 0.4, 3.0), concrete)
		_add_box(Vector3(0.0, 12.0, s * 88.0), Vector3(120.0, 10.0, 8.0), concrete)
	# pared baja del lado de la cámara
	_add_box(Vector3(-46.0, 1.5, 0.0), Vector3(3.0, 3.0, 130.0), concrete)

	# bancos de suplentes con techo (dugouts, lado de la cámara)
	var bench := _mat(Color(0.7, 0.7, 0.72), 0.8, true)
	for s in [-1.0, 1.0]:
		_add_box(Vector3(-40.0, 0.5, s * 18.0), Vector3(2.0, 1.0, 8.0), bench)
		_add_box(Vector3(-40.8, 1.1, s * 18.0), Vector3(0.4, 1.2, 8.0), bench)
		_add_box(Vector3(-40.6, 2.5, s * 18.0), Vector3(3.0, 0.15, 9.0), roof)
		_add_box(Vector3(-42.0, 1.3, s * 18.0), Vector3(0.15, 2.6, 9.0), roof)

	# banderines de esquina
	var corner_mat := _mat(Color(1.0, 0.55, 0.1), 0.7)
	for sx in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			var flag := MeshInstance3D.new()
			var fm2 := PrismMesh.new()
			fm2.size = Vector3(0.05, 0.4, 0.3)
			flag.mesh = fm2
			flag.material_override = corner_mat
			flag.position = Vector3(sx * (W - 0.3), 1.35, sz2 * (TRY - 0.3))
			add_child(flag)
			var cpole := MeshInstance3D.new()
			var cpm := CylinderMesh.new()
			cpm.top_radius = 0.025
			cpm.bottom_radius = 0.025
			cpm.height = 1.4
			cpole.mesh = cpm
			cpole.material_override = _mat(Color(0.9, 0.9, 0.9))
			cpole.position = Vector3(sx * (W - 0.3), 0.7, sz2 * (TRY - 0.3))
			add_child(cpole)

	# logo central de la URT
	var ring := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 6.0
	rm.bottom_radius = 6.0
	rm.height = 0.012
	ring.mesh = rm
	var ring_mat := _mat(Color(0.95, 0.55, 0.1))
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color.a = 0.35
	ring.material_override = ring_mat
	ring.position = Vector3(0.0, 0.02, 0.0)
	add_child(ring)
	var logo := Label3D.new()
	logo.text = "U R T"
	logo.font_size = 256
	logo.pixel_size = 0.06
	logo.modulate = Color(1.0, 1.0, 1.0, 0.5)
	logo.rotation.x = -PI / 2.0
	logo.position = Vector3(0.0, 0.05, 0.0)
	add_child(logo)

	# cartel en la tribuna principal
	var cartel := Label3D.new()
	cartel.text = "UNION DE RUGBY DE TUCUMAN"
	cartel.font_size = 128
	cartel.pixel_size = 0.12
	cartel.modulate = Color(1.0, 0.85, 0.3)
	cartel.rotation.y = -PI / 2.0
	cartel.position = Vector3(61.9, 13.0, 0.0)
	add_child(cartel)


func _build_floodlights() -> void:
	var pole_mat := _mat(Color(0.35, 0.36, 0.4), 0.7)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(1.0, 1.0, 0.9)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.98, 0.85)
	lamp_mat.emission_energy_multiplier = 2.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var base := Vector3(sx * 52.0, 0.0, sz * 78.0)
			_add_box(base + Vector3(0, 11.0, 0), Vector3(1.2, 22.0, 1.2), pole_mat)
			_add_box(base + Vector3(0, 22.6, 0), Vector3(5.0, 2.0, 1.6), pole_mat)
			for i in 3:
				var lamp := MeshInstance3D.new()
				var lm := BoxMesh.new()
				lm.size = Vector3(1.2, 1.0, 0.4)
				lamp.mesh = lm
				lamp.material_override = lamp_mat
				lamp.position = base + Vector3(-1.5 + i * 1.5, 22.6, -sz * 0.7)
				add_child(lamp)
			# foco real para los partidos nocturnos
			var spot := SpotLight3D.new()
			spot.position = base + Vector3(0.0, 21.8, 0.0)
			spot.spot_range = 150.0
			spot.spot_angle = 42.0
			spot.light_energy = 4.0
			spot.light_color = Color(1.0, 0.96, 0.85)
			spot.visible = false
			add_child(spot)
			spot.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
			floodlights.append(spot)


# momento del día: día, atardecer o noche (con focos encendidos)
func set_daytime(mode: String) -> void:
	if env_node == null or sun_node == null:
		return
	var psm := env_node.environment.sky.sky_material as ProceduralSkyMaterial
	match mode:
		"day":
			sun_node.light_energy = 1.35
			sun_node.light_color = Color(1.0, 0.98, 0.94)
			sun_node.rotation_degrees = Vector3(-62.0, -20.0, 0.0)
			if psm != null:
				psm.sky_top_color = Color(0.28, 0.5, 0.85)
				psm.sky_horizon_color = Color(0.72, 0.8, 0.9)
				psm.ground_bottom_color = Color(0.25, 0.3, 0.3)
			env_node.environment.ambient_light_energy = 0.9
		"night":
			sun_node.light_energy = 0.18
			sun_node.light_color = Color(0.55, 0.65, 1.0)
			if psm != null:
				psm.sky_top_color = Color(0.01, 0.03, 0.1)
				psm.sky_horizon_color = Color(0.06, 0.08, 0.16)
				psm.ground_bottom_color = Color(0.01, 0.02, 0.04)
			env_node.environment.ambient_light_energy = 0.28
		_:  # "sunset": el look original
			sun_node.light_energy = 1.1
			sun_node.light_color = Color(1.0, 0.92, 0.8)
			sun_node.rotation_degrees = Vector3(-52.0, -25.0, 0.0)
			if psm != null:
				psm.sky_top_color = Color(0.16, 0.3, 0.62)
				psm.sky_horizon_color = Color(0.75, 0.62, 0.5)
				psm.ground_bottom_color = Color(0.2, 0.22, 0.25)
			env_node.environment.ambient_light_energy = 0.75
	for s in floodlights:
		s.visible = mode == "night"


func _build_photographers() -> void:
	var cam_mat := _mat(Color(0.08, 0.09, 0.12), 0.6)
	var vest := Color(0.95, 0.75, 0.15)          # pechera de fotógrafo
	var spots := [
		Vector3(-39.0, 0.0, -66.0), Vector3(39.0, 0.0, 66.0),
		Vector3(-39.0, 0.0, 66.0), Vector3(39.0, 0.0, -66.0)]
	for sp in spots:
		var h := Humanoid.make({
			"bulk": 0.9, "skin": Color(0.8, 0.62, 0.45),
			"jersey": vest, "trim": Color(0.1, 0.1, 0.1),
			"shorts": Color(0.15, 0.15, 0.2), "jersey_tex": null,
			"number": 0})
		h.position = sp
		h.scale = Vector3(0.8, 0.62, 0.8)       # arrodillado
		add_child(h)
		h.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		_add_box(sp + Vector3(0.0, 1.0, 0.0) +
			Vector3(-signf(sp.x), 0.0, 0.0) * 0.5,
			Vector3(0.35, 0.22, 0.5), cam_mat)
	# camarógrafo parado en la mitad de la cancha
	var cam_pos := Vector3(-42.0, 0.0, 0.0)
	var h2 := Humanoid.make({
		"bulk": 1.0, "skin": Color(0.75, 0.55, 0.4),
		"jersey": Color(0.12, 0.12, 0.15), "trim": Color(0.9, 0.9, 0.9),
		"shorts": Color(0.1, 0.1, 0.12), "jersey_tex": null, "number": 0})
	h2.position = cam_pos
	add_child(h2)
	h2.look_at(Vector3(0.0, 1.5, 0.0), Vector3.UP)
	_add_box(cam_pos + Vector3(1.0, 1.6, 0.0), Vector3(0.5, 0.35, 0.7), cam_mat)


func _build_crowd() -> void:
	# público con MultiMesh: un draw call para ~2500 espectadores
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	crowd_palette = [
		Color(0.9, 0.2, 0.2), Color(0.95, 0.95, 0.9), Color(0.2, 0.3, 0.7),
		Color(0.9, 0.6, 0.15), Color(0.15, 0.5, 0.25), Color(0.7, 0.7, 0.75),
		Color(0.3, 0.3, 0.35), Color(0.95, 0.55, 0.2),
	]
	var palette: Array = crowd_palette
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.9, 0.45)
	mm.mesh = mesh

	var positions: Array[Vector3] = []
	# tribuna principal (gradas en +X): espectadores parados SOBRE cada escalón.
	# Escalón i: centro y = 1.2+i*1.6, alto = 2.4+i*0.4 → tope = 2.4+i*1.8
	for row in 6:
		for i in 120:
			positions.append(Vector3(46.0 + row * 3.0 + rng.randf_range(-0.6, 0.6),
				2.4 + row * 1.8 + 0.5 + rng.randf_range(0.0, 0.15),
				-60.0 + i * 1.0 + rng.randf_range(-0.3, 0.3)))
	# fondos
	for s in [-1.0, 1.0]:
		for row in 5:
			for i in 90:
				positions.append(Vector3(-45.0 + i * 1.0 + rng.randf_range(-0.3, 0.3),
					2.4 + row * 1.8 + 0.5 + rng.randf_range(0.0, 0.15),
					s * (70.0 + row * 3.0) + rng.randf_range(-0.5, 0.5)))

	crowd_pos = positions.duplicate()
	mm.instance_count = positions.size()
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	add_child(inst)
	crowd_mm = mm
	for i in positions.size():
		var t := Transform3D(Basis.IDENTITY, positions[i])
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, palette[rng.randi() % palette.size()])


# banderas en lo alto de las gradas; se tiñen con los clubes del partido
func _build_flags() -> void:
	var spots: Array[Vector3] = []
	for i in 8:   # tribuna principal (+X), lo alto
		spots.append(Vector3(44.5, 11.5, -52.0 + i * 15.0))
	for s in [-1.0, 1.0]:   # fondos
		for i in 3:
			spots.append(Vector3(-30.0 + i * 30.0, 9.6, s * 81.0))
	for pos in spots:
		var pole := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.03
		pm.bottom_radius = 0.03
		pm.height = 2.6
		pole.mesh = pm
		pole.position = pos
		pole.material_override = _mat(Color(0.75, 0.75, 0.78))
		add_child(pole)
		var fm := StandardMaterial3D.new()
		fm.albedo_color = Color(0.85, 0.85, 0.85)
		fm.roughness = 0.8
		fm.cull_mode = BaseMaterial3D.CULL_DISABLED
		flag_mats.append(fm)
		var flag := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.7, 1.05)
		flag.mesh = q
		flag.material_override = fm
		# cuelga del asta hacia la cancha
		if absf(pos.x) > 40.0:
			flag.rotation.y = -PI / 2.0
			flag.position = pos + Vector3(0.0, 0.9, 0.9)
		else:
			flag.rotation.y = PI if pos.z < 0.0 else 0.0
			flag.position = pos + Vector3(0.9, 0.9, 0.0)
		add_child(flag)


# pantallas gigantes en los fondos, tintadas con los clubes del partido
func _build_screens() -> void:
	for sz2 in [-1.0, 1.0]:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.2, 0.2, 0.25)
		sm.emission_enabled = true
		sm.emission = Color(0.2, 0.2, 0.25)
		sm.emission_energy_multiplier = 1.6
		screen_mats.append(sm)
		var scr := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(9.0, 4.5)
		scr.mesh = q
		scr.material_override = sm
		scr.position = Vector3(-8.0, 10.5, sz2 * 82.0)
		scr.rotation.y = 0.0 if sz2 > 0.0 else PI
		add_child(scr)


# ola permanente sutil; crowd_surge() la dispara en los tries
func _process(delta: float) -> void:
	if crowd_mm == null or crowd_pos.is_empty():
		return
	wave_t += delta * 2.4
	wave_amp = maxf(0.0, wave_amp - delta * 0.45)
	var amp := 0.10 + wave_amp * 0.6
	for i in crowd_mm.instance_count:
		var bp := crowd_pos[i]
		var ph := bp.z * 0.30 + bp.x * 0.12
		var y := bp.y + maxf(0.0, sin(wave_t + ph)) * amp
		crowd_mm.set_instance_transform(i,
			Transform3D(Basis.IDENTITY, Vector3(bp.x, y, bp.z)))


func crowd_surge() -> void:
	wave_amp = 1.0


# Tiñe parte de la hinchada con los colores de los clubes que juegan.
func tint_crowd(home_c: Color, away_c: Color) -> void:
	for i in flag_mats.size():
		flag_mats[i].albedo_color = home_c if i % 2 == 0 else away_c
	for i in screen_mats.size():
		var sc: Color = home_c if i == 0 else away_c
		screen_mats[i].albedo_color = sc
		screen_mats[i].emission = sc
	if crowd_mm == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in crowd_mm.instance_count:
		var r := rng.randf()
		if r < 0.22:
			crowd_mm.set_instance_color(i, home_c.lightened(rng.randf() * 0.3))
		elif r < 0.36:
			crowd_mm.set_instance_color(i, away_c.lightened(rng.randf() * 0.3))
		else:
			crowd_mm.set_instance_color(i,
				crowd_palette[rng.randi() % crowd_palette.size()])
