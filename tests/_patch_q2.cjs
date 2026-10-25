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

/* ═══ teams.gd — camisetas en 2048 con operaciones nativas (rápidas) ═══ */
patch("scripts/teams.gd", [
[`	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	match club["pattern"]:
		Pattern.HOOPS:
			for y in 96:
				var band := int(y / 16.0) % 2
				_fill_row(img, y, cols[band])
		Pattern.HOOPS3:
			for y in 96:
				var band := int(y / 12.0) % 3
				_fill_row(img, y, cols[band % cols.size()])
		Pattern.STRIPES2:
			img.fill(cols[0])
			_fill_rect(img, 0, 30, 96, 12, cols[1])
			_fill_rect(img, 0, 52, 96, 12, cols[2] if cols.size() > 2 else cols[1])
		Pattern.CHECKERED:
			for y in 96:
				for x in 96:
					var c: Color = cols[(int(x / 16.0) + int(y / 16.0)) % 2]
					img.set_pixel(x, y, c)
		Pattern.CROSS:
			img.fill(cols[0])
			var cc: Color = cols[2] if cols.size() > 2 else cols[1]
			# cruz: exterior en color 1, núcleo en color 2 (amarillo en Cardenales)
			_fill_rect(img, 38, 0, 20, 96, cols[1])
			_fill_rect(img, 0, 38, 96, 20, cols[1])
			_fill_rect(img, 44, 0, 8, 96, cc)
			_fill_rect(img, 0, 44, 96, 8, cc)
		Pattern.COLLAR:
			img.fill(cols[0])
			_fill_rect(img, 0, 0, 96, 12, cols[1])      # cuello
			_fill_rect(img, 0, 86, 96, 10, cols[1])    # bastilla`,
`	var img := Image.create(JRES, JRES, false, Image.FORMAT_RGBA8)
	var K := JRES / 96.0   # factor de escala desde el diseño original 96px
	match club["pattern"]:
		Pattern.HOOPS:
			for b in 6:
				img.fill_rect(Rect2i(0, int(b * 16 * K), JRES, int(16 * K) + 2),
					cols[b % 2])
		Pattern.HOOPS3:
			for b in 8:
				img.fill_rect(Rect2i(0, int(b * 12 * K), JRES, int(12 * K) + 2),
					cols[b % cols.size()])
		Pattern.STRIPES2:
			img.fill(cols[0])
			img.fill_rect(Rect2i(0, int(30 * K), JRES, int(12 * K)), cols[1])
			img.fill_rect(Rect2i(0, int(52 * K), JRES, int(12 * K)),
				cols[2] if cols.size() > 2 else cols[1])
		Pattern.CHECKERED:
			var cell := int(16 * K)
			for cy in 6:
				for cx in 6:
					img.fill_rect(Rect2i(cx * cell, cy * cell, cell + 1, cell + 1),
						cols[(cx + cy) % 2])
		Pattern.CROSS:
			img.fill(cols[0])
			var cc: Color = cols[2] if cols.size() > 2 else cols[1]
			# cruz: exterior en color 1, núcleo en color 2 (amarillo en Cardenales)
			img.fill_rect(Rect2i(int(38 * K), 0, int(20 * K), JRES), cols[1])
			img.fill_rect(Rect2i(0, int(38 * K), JRES, int(20 * K)), cols[1])
			img.fill_rect(Rect2i(int(44 * K), 0, int(8 * K), JRES), cc)
			img.fill_rect(Rect2i(0, int(44 * K), JRES, int(8 * K)), cc)
		Pattern.COLLAR:
			img.fill(cols[0])
			img.fill_rect(Rect2i(0, 0, JRES, int(12 * K)), cols[1])          # cuello
			img.fill_rect(Rect2i(0, int(86 * K), JRES, int(10 * K)), cols[1]) # bastilla`],
[`# tela con grano, sombreado vertical (más claro arriba) y cuello en V
static func _detail_jersey(img: Image, seed_v: int, cols: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 7919 + 13
	var collar: Color = (cols[1] if cols.size() > 1 else cols[0]).darkened(0.25)
	for y in 96:
		var shade := 1.08 - float(y) / 96.0 * 0.16   # caída de luz
		for x in 96:
			var c := img.get_pixel(x, y)
			var n := rng.randf_range(-0.055, 0.055)
			c = Color(c.r * (shade + n), c.g * (shade + n), c.b * (shade + n))
			if y < 11 and absf(float(x) - 48.0) < float(11 - y) * 1.7:
				c = collar          # escote en V
			img.set_pixel(x, y, c)
	# bastilla inferior un toque más oscura
	for y in range(92, 96):
		for x in 96:
			var c := img.get_pixel(x, y).darkened(0.12)
			img.set_pixel(x, y, c)`,
`# tela: sombreado vertical (overlay translúcido nativo), grano por capa de
# detalle del material y escote en V — todo a 2048 sin bucles por píxel
const JRES := 2048
static var _shade_img: Image = null

static func _shade() -> Image:
	if _shade_img == null:
		_shade_img = Image.create(JRES, JRES, false, Image.FORMAT_RGBA8)
		# 64 franjas translúcidas: más claras arriba, más oscuras abajo
		var band := JRES / 64
		for b in 64:
			var k := float(b) / 63.0 - 0.5          # -0.5 arriba … +0.5 abajo
			var c := Color(0.0, 0.0, 0.0, k * 0.30) if k > 0.0 \
				else Color(1.0, 1.0, 1.0, -k * 0.22)
			_shade_img.fill_rect(Rect2i(0, b * band, JRES, band + 1), c)
	return _shade_img


static func _detail_jersey(img: Image, seed_v: int, cols: Array) -> void:
	var K := JRES / 96.0
	img.blend_rect(_shade(), Rect2i(0, 0, JRES, JRES), Vector2i.ZERO)
	var collar: Color = (cols[1] if cols.size() > 1 else cols[0]).darkened(0.25)
	# escote en V: fila a fila con fill_rect (nativo, rápido)
	for y in int(11 * K):
		var half := int((11.0 - float(y) / K) * 1.7 * K)
		img.fill_rect(Rect2i(int(48 * K) - half, y, half * 2, 1), collar)
	# bastilla inferior un toque más oscura
	img.blend_rect(_hem_img(), Rect2i(0, 0, JRES, JRES), Vector2i.ZERO)


static var _hem_img: Image = null
static func _hem_img() -> Image:
	if _hem_img == null:
		_hem_img = Image.create(JRES, JRES, false, Image.FORMAT_RGBA8)
		_hem_img.fill_rect(Rect2i(0, int(JRES * 92.0 / 96.0), JRES,
			JRES - int(JRES * 92.0 / 96.0)), Color(0.0, 0.0, 0.0, 0.22))
	return _hem_img`],
[`static func _fill_row(img: Image, y: int, c: Color) -> void:
	for x in 96:
		img.set_pixel(x, y, c)


static func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			img.set_pixel(x, y, c)`,
`# textura compartida de fibra de tela para el canal "detail" del material
static var _fabric_tex: Texture2D = null
static func fabric_texture() -> Texture2D:
	if _fabric_tex == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX
		n.frequency = 0.55
		n.fractal_octaves = 3
		var nt := NoiseTexture2D.new()
		nt.width = JRES
		nt.height = JRES
		nt.seamless = true
		nt.noise = n
		_fabric_tex = nt
	return _fabric_tex`],
]);
