extends RefCounted
class_name RugbyTeams

# Clubes de la Unión de Rugby de Tucumán con la indumentaria oficial
# (fuente: descripciones de camiseta en urtuc.com.ar/pagina/300/clubes).
# pattern: HOOPS rayas horizontales 2 colores · HOOPS3 3 colores ·
#          STRIPES2 base + 2 franjas · CHECKERED cuadros · CROSS cruz ·
#          COLLAR lisa con cuello/bastilla de otro color.
enum Pattern { HOOPS, HOOPS3, STRIPES2, CHECKERED, CROSS, COLLAR }

static var CLUBS := [
	{
		"name": "Tucumán Rugby Club", "abbr": "TRC", "city": "Yerba Buena",
		"pattern": Pattern.CHECKERED,
		"colors": [Color.html("#1b5e33"), Color.html("#141414")],
		"primary": Color.html("#1b5e33"), "secondary": Color.html("#141414"),
		"shorts": Color.html("#f2f2f2"), "rating": 1.05,
	},
	{
		"name": "Universitario Rugby Club", "abbr": "UNI", "city": "S.M. de Tucumán",
		"pattern": Pattern.HOOPS,
		"colors": [Color.html("#2e4a8f"), Color.html("#8a94a6")],
		"primary": Color.html("#2e4a8f"), "secondary": Color.html("#8a94a6"),
		"shorts": Color.html("#2e4a8f"), "rating": 1.05,
	},
	{
		"name": "Los Tarcos Rugby Club", "abbr": "TAR", "city": "S.M. de Tucumán",
		"pattern": Pattern.COLLAR,
		"colors": [Color.html("#b71c1c"), Color.html("#f2f2f2")],
		"primary": Color.html("#b71c1c"), "secondary": Color.html("#f2f2f2"),
		"shorts": Color.html("#f2f2f2"), "rating": 1.0,
	},
	{
		"name": "Club Natación y Gimnasia", "abbr": "NYG", "city": "S.M. de Tucumán",
		"pattern": Pattern.STRIPES2,
		"colors": [Color.html("#f2f2f2"), Color.html("#1a3d8f"), Color.html("#dc2626")],
		"primary": Color.html("#f2f2f2"), "secondary": Color.html("#1a3d8f"),
		"shorts": Color.html("#f2f2f2"), "rating": 1.1,
	},
	{
		"name": "Tucumán Lawn Tennis Club", "abbr": "LAW", "city": "S.M. de Tucumán",
		"pattern": Pattern.HOOPS3,
		"colors": [Color.html("#f5f5f5"), Color.html("#1a3d8f"), Color.html("#ffd400")],
		"primary": Color.html("#f5f5f5"), "secondary": Color.html("#ffd400"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.98,
	},
	{
		"name": "Cardenales Rugby Club", "abbr": "CAR", "city": "S.M. de Tucumán",
		"pattern": Pattern.CROSS,
		"colors": [Color.html("#a31621"), Color.html("#1a1a1a"), Color.html("#ffd400")],
		"primary": Color.html("#a31621"), "secondary": Color.html("#1a1a1a"),
		"shorts": Color.html("#1a1a1a"), "rating": 0.97,
	},
	{
		"name": "Huirapuca S.C.", "abbr": "HUI", "city": "Concepción",
		"pattern": Pattern.HOOPS,
		"colors": [Color.html("#14532d"), Color.html("#b91c1c")],
		"primary": Color.html("#14532d"), "secondary": Color.html("#b91c1c"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.97,
	},
	{
		"name": "Jockey Club de Tucumán", "abbr": "JCK", "city": "Yerba Buena",
		"pattern": Pattern.STRIPES2,
		"colors": [Color.html("#f8f8f8"), Color.html("#7a1f2b"), Color.html("#38bdf8")],
		"primary": Color.html("#f8f8f8"), "secondary": Color.html("#7a1f2b"),
		"shorts": Color.html("#7a1f2b"), "rating": 0.95,
	},
	{
		"name": "Lince Rugby Club", "abbr": "LIN", "city": "S.M. de Tucumán",
		"pattern": Pattern.HOOPS,
		"colors": [Color.html("#9ca3af"), Color.html("#b91c1c")],
		"primary": Color.html("#9ca3af"), "secondary": Color.html("#b91c1c"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.93,
	},
	{
		"name": "Corsarios Rugby Club", "abbr": "COR", "city": "S.M. de Tucumán",
		"pattern": Pattern.COLLAR,
		"colors": [Color.html("#171717"), Color.html("#f2f2f2")],
		"primary": Color.html("#171717"), "secondary": Color.html("#f2f2f2"),
		"shorts": Color.html("#171717"), "rating": 0.92,
	},
	{
		"name": "Bajo Hondo Rugby Club", "abbr": "BAJ", "city": "S.M. de Tucumán",
		"pattern": Pattern.HOOPS,
		"colors": [Color.html("#1c1c1c"), Color.html("#f97316")],
		"primary": Color.html("#1c1c1c"), "secondary": Color.html("#f97316"),
		"shorts": Color.html("#1c1c1c"), "rating": 0.9,
	},
	{
		"name": "Aguará Guazú", "abbr": "AGU", "city": "Aguilares",
		"pattern": Pattern.HOOPS,
		"colors": [Color.html("#1e40af"), Color.html("#dc2626")],
		"primary": Color.html("#1e40af"), "secondary": Color.html("#dc2626"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.9,
	},
]

const NYG_INDEX := 3  # Natación y Gimnasia: actual campeón anual 2026

static var _tex_cache := {}


# Genera la textura 96x96 de la camiseta según el patrón oficial del club.
# alt=true invierte los colores (kit visitante cuando hay choque).
static func jersey_texture(idx: int, alt := false) -> Texture2D:
	var key := "%d|%d" % [idx, int(alt)]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var club: Dictionary = CLUBS[idx]
	var cols: Array = club["colors"].duplicate()
	if alt and cols.size() >= 2:
		var tmp = cols[0]
		cols[0] = cols[1]
		cols[1] = tmp
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
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
			_fill_rect(img, 0, 86, 96, 10, cols[1])    # bastilla
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


static func _fill_row(img: Image, y: int, c: Color) -> void:
	for x in 96:
		img.set_pixel(x, y, c)


static func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			img.set_pixel(x, y, c)
