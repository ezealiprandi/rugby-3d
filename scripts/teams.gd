extends RefCounted
class_name RugbyTeams

# Clubes de la Unión de Rugby de Tucumán con sus colores oficiales (fuente: urtuc.com.ar).
# primary = color base de camiseta, secondary = banda/detalle, shorts = pantalón.
# rating: fuerza relativa del equipo (afecta velocidad y agresividad de la IA).
static var CLUBS := [
	{
		"name": "Tucumán Rugby Club", "abbr": "TRC", "city": "Yerba Buena",
		"primary": Color.html("#1b5e33"), "secondary": Color.html("#141414"),
		"shorts": Color.html("#f2f2f2"), "rating": 1.05,
	},
	{
		"name": "Universitario Rugby Club", "abbr": "UNI", "city": "S.M. de Tucumán",
		"primary": Color.html("#2e4a8f"), "secondary": Color.html("#8a94a6"),
		"shorts": Color.html("#2e4a8f"), "rating": 1.05,
	},
	{
		"name": "Los Tarcos Rugby Club", "abbr": "TAR", "city": "S.M. de Tucumán",
		"primary": Color.html("#b71c1c"), "secondary": Color.html("#f2f2f2"),
		"shorts": Color.html("#f2f2f2"), "rating": 1.0,
	},
	{
		"name": "Club Natación y Gimnasia", "abbr": "NYG", "city": "S.M. de Tucumán",
		"primary": Color.html("#f2f2f2"), "secondary": Color.html("#1a3d8f"),
		"shorts": Color.html("#f2f2f2"), "rating": 1.1,
	},
	{
		"name": "Tucumán Lawn Tennis Club", "abbr": "LAW", "city": "S.M. de Tucumán",
		"primary": Color.html("#f5f5f5"), "secondary": Color.html("#ffd400"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.98,
	},
	{
		"name": "Cardenales Rugby Club", "abbr": "CAR", "city": "S.M. de Tucumán",
		"primary": Color.html("#a31621"), "secondary": Color.html("#1a1a1a"),
		"shorts": Color.html("#1a1a1a"), "rating": 0.97,
	},
	{
		"name": "Huirapuca S.C.", "abbr": "HUI", "city": "Concepción",
		"primary": Color.html("#14532d"), "secondary": Color.html("#b91c1c"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.97,
	},
	{
		"name": "Jockey Club de Tucumán", "abbr": "JCK", "city": "Yerba Buena",
		"primary": Color.html("#f8f8f8"), "secondary": Color.html("#7a1f2b"),
		"shorts": Color.html("#7a1f2b"), "rating": 0.95,
	},
	{
		"name": "Lince Rugby Club", "abbr": "LIN", "city": "S.M. de Tucumán",
		"primary": Color.html("#9ca3af"), "secondary": Color.html("#b91c1c"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.93,
	},
	{
		"name": "Corsarios Rugby Club", "abbr": "COR", "city": "S.M. de Tucumán",
		"primary": Color.html("#171717"), "secondary": Color.html("#f2f2f2"),
		"shorts": Color.html("#171717"), "rating": 0.92,
	},
	{
		"name": "Bajo Hondo Rugby Club", "abbr": "BAJ", "city": "S.M. de Tucumán",
		"primary": Color.html("#1c1c1c"), "secondary": Color.html("#f97316"),
		"shorts": Color.html("#1c1c1c"), "rating": 0.9,
	},
	{
		"name": "Aguará Guazú", "abbr": "AGU", "city": "Aguilares",
		"primary": Color.html("#1e40af"), "secondary": Color.html("#dc2626"),
		"shorts": Color.html("#f2f2f2"), "rating": 0.9,
	},
]

const NYG_INDEX := 3  # Natación y Gimnasia: actual campeón anual 2026
