const fs = require("fs");
let ok = true;
function patch(f, subs) {
  let s = fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n");
  for (const [o, n] of subs) {
    if (!s.includes(o)) { console.log("MISS in " + f + ": " + o.slice(0, 80).replace(/\n/g, "\n")); ok = false; continue; }
    s = s.split(o).join(n);
  }
  fs.writeFileSync(f, s);
}

patch("scripts/field.gd", [
// refs a los materiales de pasto para el barro
[`var rain: GPUParticles3D`,
`var rain: GPUParticles3D
var grass_mats: Array[ShaderMaterial] = []`],
// ruido de cemento a 2048
[`		nt.width = 256
		nt.height = 256`,
`		nt.width = 2048
		nt.height = 2048`],
// shader de pasto con barro sutil cuando llueve
[`uniform vec4 color : source_color;`,
`uniform vec4 color : source_color;
uniform float wet : hint_range(0.0, 1.0) = 0.0;`],
[`	float mow = step(0.5, fract(VERTEX.x * 0.35)) * 0.05;   // líneas de corte
	ALBEDO = color.rgb * (0.72 + patch * 0.18 + mid * 0.12
		+ grain * 0.10 + mow);
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;`,
`	float mow = step(0.5, fract(VERTEX.x * 0.35)) * 0.05;   // líneas de corte
	vec3 grass_c = color.rgb * (0.72 + patch * 0.18 + mid * 0.12
		+ grain * 0.10 + mow);
	// barro sutil en la zona de tránsito: manchones marrones solo con lluvia
	float center = 1.0 - clamp(abs(VERTEX.z) / 46.0, 0.0, 1.0);
	float mudmask = smoothstep(0.62, 0.8, patch * 0.6 + mid * 0.4)
		* center * wet;
	vec3 mud_c = vec3(0.24, 0.17, 0.1) * (0.85 + grain * 0.3);
	ALBEDO = mix(grass_c, mud_c, mudmask * 0.55);
	ROUGHNESS = 0.92 - wet * 0.3;   // el pasto mojado refleja un poco más
	SPECULAR = 0.25 + wet * 0.15;`],
// guardar refs para set_weather
[`	var green_a := ShaderMaterial.new()
	green_a.shader = grass_shader
	green_a.set_shader_parameter("color", Color(0.15, 0.4, 0.15))
	var green_b := ShaderMaterial.new()
	green_b.shader = grass_shader
	green_b.set_shader_parameter("color", Color(0.19, 0.48, 0.19))`,
`	var green_a := ShaderMaterial.new()
	green_a.shader = grass_shader
	green_a.set_shader_parameter("color", Color(0.15, 0.4, 0.15))
	var green_b := ShaderMaterial.new()
	green_b.shader = grass_shader
	green_b.set_shader_parameter("color", Color(0.19, 0.48, 0.19))
	grass_mats = [green_a, green_b]`],
// set_weather activa el barro
[`	if is_rain:
		if rain == null:
			_make_rain()
		rain.emitting = true
	elif rain != null:
		rain.emitting = false`,
`	for gm in grass_mats:
		gm.set_shader_parameter("wet", 1.0 if is_rain else 0.0)
	if is_rain:
		if rain == null:
			_make_rain()
		rain.emitting = true
	elif rain != null:
		rain.emitting = false`],
// vallas publicitarias en HD (diagonales nativas por columnas)
[`func _ad_mat(c1: Color, c2: Color) -> StandardMaterial3D:
	var img := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 128:
			img.set_pixel(x, y, c1 if int((x + y * 2) / 16) % 2 == 0 else c2)`,
`func _ad_mat(c1: Color, c2: Color) -> StandardMaterial3D:
	const AW := 2048
	const AH := 512
	var img := Image.create(AW, AH, false, Image.FORMAT_RGBA8)
	img.fill(c2)
	var cell := int(AW / 8.0)
	for i in 18:                     # franjas diagonales anchas
		var x0 := i * cell - AH
		img.fill_rect(Rect2i(x0, 0, int(cell * 0.62), AH), c1)`],
// cabina de transmisión con presentadores sobre la tribuna principal
[`	# bancos de suplentes con techo (dugouts, lado de la cámara)`,
`	_build_press_box()

	# bancos de suplentes con techo (dugouts, lado de la cámara)`],
[`func _build_floodlights() -> void:`,
`# cabina de transmisión URT TV sobre el techo de la tribuna principal
func _build_press_box() -> void:
	var cabin := _mat(Color(0.16, 0.17, 0.2), 0.6, true)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.55, 0.7, 0.85, 0.35)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.15
	# estructura de la cabina sobre el techo (x 62, techo y ~22.1)
	_add_box(Vector3(62.0, 24.0, 0.0), Vector3(6.0, 3.6, 14.0), cabin)
	_add_box(Vector3(59.4, 24.0, 0.0), Vector3(0.3, 2.6, 13.0), glass)   # ventanal
	_add_box(Vector3(62.0, 26.0, 0.0), Vector3(6.4, 0.4, 14.4), cabin)   # techo
	# cartel URT TV en el frente de la cabina
	var sign := Label3D.new()
	sign.text = "URT TV"
	sign.font_size = 96
	sign.modulate = Color(1.0, 0.85, 0.2)
	sign.position = Vector3(58.9, 24.6, 0.0)
	sign.rotation_degrees = Vector3(0.0, -90.0, 0.0)
	add_child(sign)
	# dos presentadores sentados detrás del ventanal
	var suit := _mat(Color(0.15, 0.16, 0.22), 0.7)
	var skin := _mat(Color(0.85, 0.66, 0.5), 0.7)
	for z in [-3.0, 3.0]:
		_add_box(Vector3(61.0, 23.2, z), Vector3(0.7, 1.1, 0.55), suit)  # torso
		_add_box(Vector3(61.0, 24.05, z), Vector3(0.42, 0.42, 0.4), skin) # cabeza
		_add_box(Vector3(60.5, 23.9, z), Vector3(0.12, 0.12, 0.5),
			_mat(Color(0.05, 0.05, 0.06), 0.5))                          # auriculares
	# escritorio de la cabina
	_add_box(Vector3(60.2, 22.9, 0.0), Vector3(0.9, 0.15, 10.0),
		_mat(Color(0.35, 0.36, 0.4), 0.5))


func _build_floodlights() -> void:`],
]);
