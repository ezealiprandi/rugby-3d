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

/* ═══ player.gd — grano de tela como capa "detail" sobre la camiseta ═══ */
patch("scripts/player.gd", [
[`	if jtex != null:
		jersey_mat.albedo_texture = jtex
		jersey_mat.albedo_color = Color(1, 1, 1)`,
`	if jtex != null:
		jersey_mat.albedo_texture = jtex
		jersey_mat.albedo_color = Color(1, 1, 1)
		# grano de tela real: capa de detalle multiplicada sobre la camiseta
		jersey_mat.detail_enabled = true
		jersey_mat.detail_albedo = RugbyTeams.fabric_texture()
		jersey_mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		jersey_mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
		jersey_mat.uv1_scale = Vector3(6.0, 6.0, 6.0)`],
]);

/* ═══ ball.gd — cuero 2048 con operaciones nativas ═══ */
patch("scripts/ball.gd", [
[`# cuero con grano, costuras oscuras en los paneles y cordones blancos
static func _leather_tex() -> Texture2D:
	var img := Image.create(256, 128, false, Image.FORMAT_RGBA8)
	var base := Color(0.58, 0.34, 0.16)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 128:
		for x in 256:
			var n := rng.randf_range(-0.045, 0.045)
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r + n, c.g + n, c.b + n))
	var seam := Color(0.3, 0.16, 0.07)
	for y in 128:                      # costuras de los 4 paneles
		for sx in [64, 128, 192]:
			img.set_pixel(sx, y, seam)
			img.set_pixel(sx + 1, y, seam)
	for y in range(38, 90, 9):         # cordones blancos sobre una costura
		for dx in range(-4, 5):
			img.set_pixel(128 + dx, y, Color(0.93, 0.9, 0.85))
			img.set_pixel(128 + dx, y + 1, Color(0.93, 0.9, 0.85))
	return ImageTexture.create_from_image(img)`,
`# cuero 2048 con grano por ruido nativo, costuras y cordones
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
	return _leather`],
]);
