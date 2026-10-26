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
# Planteles de Primera de la URT (apellidos, 1-15).
# Formaciones reales publicadas; clubes chicos completados con apellidos
# de jugadores y dirigentes del medio tucumano.
const SQUADS := [
	# TUCUMÁN RUGBY CLUB
	["Estofán", "T. Aguilar", "Díaz Vélez", "Pascal", "Guzmán J.C.",
		"Majul", "Laitán", "Heredia", "Poviña", "Domínguez",
		"Vanni", "López García", "Galíndez", "Pasquini", "Paz Uriburu"],
	# UNIVERSITARIO
	["Torres L.", "Acuña", "Mas", "Brandán E.", "Gentile",
		"Contreras Arce", "Fierro M.", "Delpero", "López Ríos",
		"Valdez Cosentino", "Brandán N.", "Cano", "Ferreyra",
		"Bonfiglioli", "Triviño"],
	# LOS TARCOS
	["El Jatib", "Lazarte", "Stenvers", "Amaya", "Laborde",
		"Picon", "Gravano", "Salsench", "Alvizo", "Alves Rojano",
		"Politti", "Salazar", "Gravano B.", "López", "Chehuan"],
	# NATACIÓN Y GIMNASIA
	["Calderón", "Escobedo", "Groso", "Ascárate", "Molina",
		"Galvez", "Juárez T.", "Villalba", "Perondi", "Molina L.",
		"Bonilla", "Brizuela", "Paliza", "Orlande", "Díaz"],
	# LAWN TENNIS
	["Bellagamba", "Salazar", "Navarro", "Argüello", "Calliera",
		"Bottini", "Jogna Prat", "Mukdise", "López Islas",
		"Rodríguez Prados", "Soberón", "Gianotti", "Manino",
		"Novillo", "Sólimo"],
	# CARDENALES
	["Brito", "Bravo I.", "Filipezuk", "Rufino", "Salanitri",
		"Lobo", "García", "Díaz I.", "Cabrera Char", "Medina L.",
		"Abi Cheble", "Odstrcil", "Muñoz", "Budeguer", "Cerrutti"],
	# HUIRAPUCA
	["Aybar", "Raso", "González F.", "Hernández Leiva", "Bralo",
		"González Ponce", "Sotillo", "Dande", "Lefebvre", "Molina J.C.",
		"Núñez Piossek", "Agüero C.", "Pérez J.", "Gutiérrez", "Soria"],
	# JOCKEY CLUB
	["Landivar", "Guraiib", "Zanoni", "Romero", "Sánchez",
		"Vega", "Paz", "Auad", "Campos", "Ibáñez",
		"Luna", "Suárez", "Arias", "Toledo", "Montero"],
	# LINCE
	["Garbero", "Palacios", "Giménez", "Salmoiraghi", "Correa",
		"Maldonado", "Rojas", "Sosa", "Núñez", "Acosta",
		"Pereyra", "Castro M.", "Luna", "Carrizo", "Bazán"],
	# CORSARIOS
	["Molina", "Arguello", "Rocha", "Di Marco", "Castro",
		"Benítez", "Guzmán", "Juárez", "Moreno", "Córdoba",
		"Lezcano", "Figueroa", "Ruiz", "Molina F.", "Sosa"],
	# BAJO HONDO
	["Lobo Chaklian", "Núñez", "Véliz", "Albornoz", "Ferreyra",
		"Carrizo", "Soria", "Ledesma", "Molina", "Paz",
		"Herrera", "Gómez", "Ruiz", "Díaz", "Toledo"],
	# AGUARÁ GUAZÚ
	["Albornoz", "Agüero", "Ponce", "Corzo", "Juárez",
		"Medina", "Andrada", "Delgado", "Savino", "Moreno",
		"Ortega", "Agüero G.", "Campos", "Villagra", "Marin"],
]


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
	var img := Image.create(JRES, JRES, false, Image.FORMAT_RGBA8)
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
			img.fill_rect(Rect2i(0, int(86 * K), JRES, int(10 * K)), cols[1]) # bastilla
	_detail_jersey(img, idx * 2 + int(alt), cols)
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


# tela: sombreado vertical (overlay translúcido nativo), grano por capa de
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
			var c := Color(0.0, 0.0, 0.0, k * 0.30) if k > 0.0 				else Color(1.0, 1.0, 1.0, -k * 0.22)
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


static var _hem: Image = null
static func _hem_img() -> Image:
	if _hem == null:
		_hem = Image.create(JRES, JRES, false, Image.FORMAT_RGBA8)
		_hem.fill_rect(Rect2i(0, int(JRES * 92.0 / 96.0), JRES,
			JRES - int(JRES * 92.0 / 96.0)), Color(0.0, 0.0, 0.0, 0.22))
	return _hem


# miniatura de 64px para íconos de menú (el ícono de Button usa tamaño nativo)
static func jersey_icon(idx: int, alt := false) -> Texture2D:
	var key := "icon%d|%d" % [idx, int(alt)]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var big: Image = jersey_texture(idx, alt).get_image()
	big.resize(64, 64, Image.INTERPOLATE_BILINEAR)
	var tex := ImageTexture.create_from_image(big)
	_tex_cache[key] = tex
	return tex


# textura compartida de fibra de tela para el canal "detail" del material
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
	return _fabric_tex
