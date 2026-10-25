extends CanvasLayer
class_name RugbyMenu

# Menú principal estilo Rugby 25 / EA Sports: panel de navegación lateral
# izquierdo con ítems grandes, zona "hero" a la derecha (muro de camisetas /
# vista previa del club) y barra inferior de hints de teclado.
enum Step { HIDDEN, TITLE, HOME, AWAY, CONTROLS, OPTIONS, TABLE }

var game: RugbyGame
var step := Step.HIDDEN
var cursor := 0
var home_idx := -1
var mode := "friendly"
var nav_idx := 0

var title_lbl: Label
var title2_lbl: Label
var subtitle_lbl: Label
var prompt_lbl: Label
var result_lbl: Label
var version_lbl: Label
var hint_lbl: Label
var champ_lbl: Label
var nav_box: VBoxContainer
var nav_btns: Array[Button] = []
var content_box: VBoxContainer
var controls_lbl: RichTextLabel
var table_lbl: RichTextLabel
var opt_box: VBoxContainer
var opt_btns: Array[Button] = []
var opt_hdrs := {}          # Label -> clave de idioma
var grid: GridContainer
var buttons: Array[Button] = []
var hero_box: VBoxContainer
var preview_box: VBoxContainer
var preview_tex: TextureRect
var preview_lbl: Label
var right_vb: VBoxContainer
var nav_desc: Label
var pulse_t := 0.0
var sfx_tick: AudioStreamPlayer
var sfx_confirm: AudioStreamPlayer


const EN := {
	"AMISTOSO": "FRIENDLY",
	"TORNEO URT": "URT TOURNAMENT",
	"TORNEO URT · 11 fechas": "URT TOURNAMENT · 11 rounds",
	"PRÁCTICA LIBRE": "FREE PRACTICE",
	"CONTROLES": "CONTROLS",
	"OPCIONES": "OPTIONS",
	"Unión de Rugby de Tucumán": "Tucumán Rugby Union",
	"Edición clubes · 15 vs 15": "Clubs edition · 15 vs 15",
	"LOS 12 CLUBES DE LA URT": "THE 12 URT CLUBS",
	"ÚLTIMO CAMPEÓN": "LAST CHAMPION",
	"ELEGÍ TU EQUIPO": "CHOOSE YOUR TEAM",
	"ELEGÍ EL RIVAL": "CHOOSE THE OPPONENT",
	" — TORNEO URT": " — URT TOURNAMENT",
	" — tu equipo: ": " — your team: ",
	"CAMPEÓN 2026": "2026 CHAMPION",
	"PARTIDO": "MATCH", "GRÁFICOS": "GRAPHICS", "AUDIO": "AUDIO",
	"ACCESIBILIDAD": "ACCESSIBILITY", "IDIOMA": "LANGUAGE",
	"TABLA URT": "URT TABLE",
	"Todavía no jugaste el torneo.\nElegí TORNEO URT para empezar.":
		"You haven't played the tournament yet.\nChoose URT TOURNAMENT to start.",
	"Próxima fecha": "Next fixture",
	"FECHA": "ROUND",
	"TABLA URT —": "URT TABLE —",
	"Duración del tiempo": "Match half length",
	"Dificultad IA": "AI difficulty",
	"Horario": "Time of day", "Clima": "Weather",
	"Aleatorio": "Random", "Día": "Day", "Atardecer": "Sunset", "Noche": "Night",
	"Despejado": "Clear", "Lluvia": "Rain",
	"Calidad gráfica": "Graphics quality", "Baja": "Low", "Media": "Medium",
	"Alta": "High",
	"Pantalla completa": "Fullscreen", "VSync": "VSync",
	"Sonido": "Sound", "Volumen": "Volume", "Sí": "Yes", "No": "No",
	"Sprint": "Sprint", "Mantener": "Hold", "Alternar": "Toggle",
	"Velocidad del juego": "Game speed", "Interfaz grande": "Big UI",
	"Idioma": "Language",
	"↑↓ navegar · Enter aceptar": "↑↓ navigate · Enter select",
	"↑↓←→ mover · Enter confirmar · Esc volver": "↑↓←→ move · Enter confirm · Esc back",
	"↑↓ elegir opción · Enter cambiar · Esc guardar": "↑↓ pick · Enter change · Esc save",
	"Esc volver": "Esc back",
	"Fácil": "Easy", "Normal": "Normal", "Difícil": "Hard",
	"min": "min",
	"Partido rápido entre dos clubes de la URT": "Quick match between two URT clubs",
	"Campeonato de 11 fechas con tabla real y campeón": "11-round championship with real table and champion",
	"Entrenamiento libre, sin reloj ni presión": "Free training, no clock, no pressure",
	"Posiciones del torneo en curso": "Standings of the ongoing tournament",
	"Juego, gráficos, audio, controles y más": "Game, graphics, audio, controls and more",
	"Todas las teclas y reglas extra": "Every key and extra rule",
}


const CONTROLS_ES := """WASD / Flechas — mover
Shift — sprint
Q / E — pase a la izquierda / derecha
Espacio — pase al apoyo más cercano
F — placaje · en el ruck: intentá robar la pelota
X — sidestep (amague lateral, difícil de placar)
B — dummy pass (amague que congela defensores)
J — fend (quitarse el placaje)
Espacio al ser placado — offload a un apoyo
C — grubber (patada rasante por el piso)
V — up and under (patada alta disputada)
Z — cross kick (al wing del lado opuesto)
T — en un penal: patada al touch (lineout propio)
K — patada larga · en un penal: a los palos (+3)
G — drop goal (en juego, cerca de los palos)
Espacio ×2 — conversión: dirección y potencia
Esc — pausa
R / M — revancha / menú (al final, o M en práctica)

Reglas extra: placaje alto y "no soltó" = penal ·
atrapar una patada rival en tus 22 = marca ·
ventaja, sin bin a los 2 penales y roja al 4°"""

const CONTROLS_EN := """WASD / Arrows — move
Shift — sprint
Q / E — pass left / right
Space — pass to nearest support
F — tackle · in the ruck: jackal for the ball
X — sidestep (harder to tackle)
B — dummy pass (freezes defenders)
J — fend
Space when tackled — offload to a support
C — grubber kick (along the ground)
V — up and under (high contestable kick)
Z — cross kick (to the far wing)
T — on a penalty: kick to touch (your lineout)
K — long kick · on a penalty: kick at goal (+3)
G — drop goal (in open play, near the posts)
Space ×2 — conversion: direction and power
Esc — pause
R / M — rematch / menu (at the end, or M in practice)

Extra rules: high tackle and "not releasing" = penalty ·
catching a rival kick inside your 22 = mark ·
advantage, sin bin at 2 penalties and red at 4"""


func T(txt: String) -> String:
	if game != null and game.opt_lang == "en":
		return EN.get(txt, txt)
	return txt


func _lbl(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


# Item grande del nav lateral: transparente, borde dorado al enfocar.
func _nav_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(400, 56)
	b.add_theme_font_size_override("font_size", 30)
	b.focus_mode = Control.FOCUS_ALL
	var flat := func(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = border
		sb.border_width_left = bw
		sb.content_margin_left = 18
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		return sb
	b.add_theme_stylebox_override("normal", flat.call(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	b.add_theme_stylebox_override("hover",
		flat.call(Color(1, 1, 1, 0.07), Color(1.0, 0.75, 0.15), 6))
	b.add_theme_stylebox_override("pressed",
		flat.call(Color(1, 1, 1, 0.15), Color(1.0, 0.75, 0.15), 6))
	b.add_theme_stylebox_override("focus",
		flat.call(Color(1, 1, 1, 0.09), Color(1.0, 0.75, 0.15), 6))
	b.add_theme_color_override("font_color", Color(0.9, 0.92, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.3))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.85, 0.3))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _btn_style(bg_color: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	sfx_tick = AudioStreamPlayer.new()
	if FileAccess.file_exists("res://assets/tick.wav"):
		sfx_tick.stream = load("res://assets/tick.wav")
		sfx_tick.volume_db = -14.0
	add_child(sfx_tick)
	sfx_confirm = AudioStreamPlayer.new()
	if FileAccess.file_exists("res://assets/confirm.wav"):
		sfx_confirm.stream = load("res://assets/confirm.wav")
		sfx_confirm.volume_db = -10.0
	add_child(sfx_confirm)

	# fondo degradado
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.09, 0.05, 0.85))
	grad.set_color(1, Color(0.01, 0.03, 0.02, 0.93))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0, 1)
	var bgt := TextureRect.new()
	bgt.texture = gtex
	bgt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bgt.stretch_mode = TextureRect.STRETCH_SCALE
	bgt.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bgt)

	# columna principal: fila (panel + hero) arriba, barra de hints abajo
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	add_child(col)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	col.add_child(row)

	# ===== panel lateral izquierdo =====
	var side := PanelContainer.new()
	side.custom_minimum_size = Vector2(500, 0)
	var side_sb := StyleBoxFlat.new()
	side_sb.bg_color = Color(0.02, 0.05, 0.035, 0.88)
	side_sb.border_color = Color(1.0, 0.75, 0.15, 0.55)
	side_sb.border_width_right = 3
	side.add_theme_stylebox_override("panel", side_sb)
	row.add_child(side)

	var smargin := MarginContainer.new()
	smargin.add_theme_constant_override("margin_left", 34)
	smargin.add_theme_constant_override("margin_right", 26)
	smargin.add_theme_constant_override("margin_top", 26)
	smargin.add_theme_constant_override("margin_bottom", 20)
	side.add_child(smargin)

	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 6)
	smargin.add_child(svb)

	# logo: RUGBY dorado + TUCUMANO 3D blanco
	title_lbl = _lbl(58)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
	title_lbl.text = "RUGBY"
	svb.add_child(title_lbl)
	title2_lbl = _lbl(42)
	title2_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	title2_lbl.text = "TUCUMANO 3D"
	svb.add_child(title2_lbl)
	subtitle_lbl = _lbl(16)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	svb.add_child(subtitle_lbl)

	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(0, 3)
	accent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accent.color = Color(1.0, 0.75, 0.15, 0.85)
	svb.add_child(accent)

	var spacer0 := Control.new()
	spacer0.custom_minimum_size = Vector2(0, 10)
	svb.add_child(spacer0)

	prompt_lbl = _lbl(24)
	prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	svb.add_child(prompt_lbl)

	# contenido scrolleable: nav / clubes / opciones / controles
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	svb.add_child(scroll)

	content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 4)
	scroll.add_child(content_box)

	nav_box = VBoxContainer.new()
	nav_box.add_theme_constant_override("separation", 2)
	content_box.add_child(nav_box)

	var nav_items := [
		["AMISTOSO", func(): _on_mode_pressed("friendly")],
		["TORNEO URT", func(): _on_mode_pressed("tournament")],
		["PRÁCTICA LIBRE", func(): _on_mode_pressed("practice")],
		["TABLA URT", _on_table_pressed],
		["OPCIONES", _on_options_pressed],
		["CONTROLES", _on_controls_pressed],
	]
	for i in nav_items.size():
		var nb := _nav_button(T(nav_items[i][0]))
		nb.pressed.connect(nav_items[i][1])
		var ii := i
		nb.focus_entered.connect(func(): _set_nav_desc(ii))
		nav_box.add_child(nb)
		nav_btns.append(nb)

	nav_desc = _lbl(16)
	nav_desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.72))
	nav_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nav_desc.custom_minimum_size = Vector2(400, 44)
	content_box.add_child(nav_desc)

	nav_box.get_parent().move_child(nav_desc, nav_box.get_index() + 1)

	# grilla de clubes (HOME/AWAY)
	grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(grid)

	var clubs: Array = RugbyTeams.CLUBS
	for i in clubs.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 42)
		b.add_theme_font_size_override("font_size", 19)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_ALL
		b.icon = RugbyTeams.jersey_texture(i)
		b.add_theme_stylebox_override("normal",
			_btn_style(Color(0.08, 0.12, 0.09, 0.9), Color(0.3, 0.4, 0.3)))
		b.add_theme_stylebox_override("hover",
			_btn_style(Color(0.15, 0.32, 0.18), clubs[i]["primary"].lightened(0.5)))
		b.add_theme_stylebox_override("pressed",
			_btn_style(Color(0.1, 0.25, 0.14), clubs[i]["primary"].lightened(0.6)))
		b.add_theme_stylebox_override("focus",
			_btn_style(Color(0.15, 0.32, 0.18), Color(1.0, 0.85, 0.2)))
		b.add_theme_stylebox_override("disabled",
			_btn_style(Color(0.05, 0.05, 0.05, 0.5), Color(0.2, 0.2, 0.2)))
		b.pressed.connect(_on_team_pressed.bind(i))
		b.mouse_entered.connect(_on_team_hover.bind(i))
		grid.add_child(b)
		buttons.append(b)

	# opciones
	opt_box = VBoxContainer.new()
	opt_box.add_theme_constant_override("separation", 4)
	opt_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_box.visible = false
	content_box.add_child(opt_box)
	var opt_layout: Array = [
		"PARTIDO", 0, 1, 2, 3,
		"GRÁFICOS", 4, 5, 6,
		"AUDIO", 7, 8,
		"CONTROLES", 9,
		"ACCESIBILIDAD", 10, 11,
		"IDIOMA", 12,
	]
	for spec in opt_layout:
		if spec is String:
			var hl := _lbl(15)
			hl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
			hl.text = "— " + spec + " —"
			hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			opt_box.add_child(hl)
			opt_hdrs[hl] = spec
		else:
			var ob := Button.new()
			ob.custom_minimum_size = Vector2(0, 36)
			ob.add_theme_font_size_override("font_size", 19)
			ob.alignment = HORIZONTAL_ALIGNMENT_LEFT
			ob.add_theme_stylebox_override("normal",
				_btn_style(Color(0.1, 0.1, 0.14, 0.9), Color(0.4, 0.35, 0.55)))
			ob.add_theme_stylebox_override("hover",
				_btn_style(Color(0.2, 0.16, 0.3), Color(0.8, 0.65, 1.0)))
			ob.add_theme_stylebox_override("focus",
				_btn_style(Color(0.2, 0.16, 0.3), Color(1.0, 0.85, 0.2)))
			ob.pressed.connect(_cycle_option.bind(spec))
			opt_box.add_child(ob)
			opt_btns.append(ob)

	# tabla del torneo (monoespaciada con [code])
	table_lbl = RichTextLabel.new()
	table_lbl.bbcode_enabled = true
	table_lbl.fit_content = true
	table_lbl.scroll_active = false
	table_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_lbl.add_theme_font_size_override("mono_font_size", 18)
	table_lbl.add_theme_font_size_override("normal_font_size", 20)
	table_lbl.add_theme_color_override("default_color", Color(0.92, 0.95, 0.9))
	table_lbl.visible = false
	content_box.add_child(table_lbl)

	# controles con BBCode (teclas en dorado)
	controls_lbl = RichTextLabel.new()
	controls_lbl.bbcode_enabled = true
	controls_lbl.fit_content = true
	controls_lbl.scroll_active = false
	controls_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_lbl.add_theme_font_size_override("normal_font_size", 20)
	controls_lbl.add_theme_color_override("default_color", Color(0.92, 0.95, 0.9))
	controls_lbl.visible = false
	content_box.add_child(controls_lbl)

	result_lbl = _lbl(19)
	result_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	result_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_lbl.visible = false
	svb.add_child(result_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	svb.add_child(spacer)

	version_lbl = _lbl(14)
	version_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
	version_lbl.text = "v5.0 · Rugby Tucumano"
	svb.add_child(version_lbl)

	# ===== zona derecha: hero (muro de camisetas) / vista previa =====
	var right := CenterContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)

	right_vb = VBoxContainer.new()
	var rvb: VBoxContainer = right_vb
	rvb.alignment = BoxContainer.ALIGNMENT_CENTER
	rvb.add_theme_constant_override("separation", 18)
	right.add_child(rvb)

	# hero: título + muro de 12 camisetas + último campeón
	hero_box = VBoxContainer.new()
	hero_box.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_box.add_theme_constant_override("separation", 14)
	rvb.add_child(hero_box)

	var hero_t := _lbl(30)
	hero_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_t.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	hero_t.text = T("LOS 12 CLUBES DE LA URT")
	hero_box.add_child(hero_t)

	var wall := GridContainer.new()
	wall.columns = 4
	wall.add_theme_constant_override("h_separation", 16)
	wall.add_theme_constant_override("v_separation", 12)
	wall.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hero_box.add_child(wall)
	for ci in clubs.size():
		var tr := TextureRect.new()
		tr.texture = RugbyTeams.jersey_texture(ci)
		tr.custom_minimum_size = Vector2(66, 84)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wall.add_child(tr)

	champ_lbl = _lbl(20)
	champ_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	champ_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	hero_box.add_child(champ_lbl)

	# franja decorativa con los 12 colores de club
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hero_box.add_child(strip)
	for c in clubs:
		var r := ColorRect.new()
		r.color = c["primary"]
		r.custom_minimum_size = Vector2(30, 10)
		strip.add_child(r)

	# vista previa del club enfocado (HOME/AWAY)
	preview_box = VBoxContainer.new()
	preview_box.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_box.add_theme_constant_override("separation", 10)
	preview_box.visible = false
	rvb.add_child(preview_box)
	preview_tex = TextureRect.new()
	preview_tex.custom_minimum_size = Vector2(240, 300)
	preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_box.add_child(preview_tex)
	preview_lbl = _lbl(24)
	preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	preview_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_box.add_child(preview_lbl)

	# ===== barra inferior de hints (estilo consola) =====
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 46)
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Color(0.01, 0.02, 0.015, 0.92)
	bar_sb.border_color = Color(1.0, 0.75, 0.15, 0.4)
	bar_sb.border_width_top = 2
	bar_sb.content_margin_left = 30
	bar.add_theme_stylebox_override("panel", bar_sb)
	col.add_child(bar)
	hint_lbl = _lbl(18)
	hint_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.add_child(hint_lbl)

	_wire_sounds()


# tick al enfocar, confirm al elegir
func _wire_sounds() -> void:
	for b in nav_btns + buttons + opt_btns:
		b.focus_entered.connect(_play_tick)
	for b in nav_btns + buttons:
		b.pressed.connect(_play_confirm)
	for b in opt_btns:
		b.pressed.connect(_play_tick)


func _play_tick() -> void:
	if sfx_tick.stream != null:
		sfx_tick.play()


func _play_confirm() -> void:
	if sfx_confirm.stream != null:
		sfx_confirm.play()


func start() -> void:
	step = Step.TITLE
	visible = true
	_update_view()


func hide_menu() -> void:
	step = Step.HIDDEN
	visible = false


func _set_nav_desc(i: int) -> void:
	nav_idx = i
	if nav_desc == null:
		return
	var keys := [
		"Partido rápido entre dos clubes de la URT",
		"Campeonato de 11 fechas con tabla real y campeón",
		"Entrenamiento libre, sin reloj ni presión",
		"Posiciones del torneo en curso",
		"Juego, gráficos, audio, controles y más",
		"Todas las teclas y reglas extra",
	]
	nav_desc.text = T(keys[i])


func _update_view() -> void:
	var is_title := step == Step.TITLE
	nav_box.visible = is_title
	nav_desc.visible = is_title
	grid.visible = step == Step.HOME or step == Step.AWAY
	opt_box.visible = step == Step.OPTIONS
	controls_lbl.visible = step == Step.CONTROLS
	table_lbl.visible = step == Step.TABLE
	hero_box.visible = is_title
	preview_box.visible = step == Step.HOME or step == Step.AWAY
	result_lbl.visible = is_title and result_lbl.text != ""
	subtitle_lbl.text = T("Unión de Rugby de Tucumán")
	champ_lbl.text = ""
	if game != null and game.last_champion >= 0:
		champ_lbl.text = "★ " + T("ÚLTIMO CAMPEÓN") + ": " + \
			RugbyTeams.CLUBS[game.last_champion]["name"] + " ★"

	match step:
		Step.TITLE:
			prompt_lbl.text = T("Edición clubes · 15 vs 15")
			hint_lbl.text = T("↑↓ navegar · Enter aceptar")
			for i in nav_btns.size():
				nav_btns[i].text = T([
					"AMISTOSO", "TORNEO URT", "PRÁCTICA LIBRE",
					"TABLA URT", "OPCIONES", "CONTROLES"][i])
			nav_btns[nav_idx].grab_focus()
			_set_nav_desc(nav_idx)
		Step.HOME:
			prompt_lbl.text = T("ELEGÍ TU EQUIPO") + \
				(T(" — TORNEO URT") if mode == "tournament" else "")
			hint_lbl.text = T("↑↓←→ mover · Enter confirmar · Esc volver")
			_fill_rows(-1)
			buttons[cursor].grab_focus()
			_update_preview()
		Step.AWAY:
			prompt_lbl.text = T("ELEGÍ EL RIVAL") + T(" — tu equipo: ") + \
				RugbyTeams.CLUBS[home_idx]["name"]
			hint_lbl.text = T("↑↓←→ mover · Enter confirmar · Esc volver")
			_fill_rows(home_idx)
			buttons[cursor].grab_focus()
			_update_preview()
		Step.CONTROLS:
			prompt_lbl.text = T("CONTROLES")
			hint_lbl.text = T("Esc volver")
			var txt: String = CONTROLS_EN if game.opt_lang == "en" else CONTROLS_ES
			controls_lbl.text = _bb_controls(txt)
		Step.TABLE:
			prompt_lbl.text = T("TABLA URT")
			hint_lbl.text = T("Esc volver")
			_fill_table()
		Step.OPTIONS:
			prompt_lbl.text = T("OPCIONES")
			hint_lbl.text = T("↑↓ elegir opción · Enter cambiar · Esc guardar")
			_refresh_options()
			opt_btns[0].grab_focus()

	# transición suave entre pantallas
	content_box.modulate.a = 0.0
	right_vb.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(content_box, "modulate:a", 1.0, 0.22)
	tw.tween_property(right_vb, "modulate:a", 1.0, 0.22)


# Colorea en dorado la tecla de cada línea de controles.
func _bb_controls(txt: String) -> String:
	var out := ""
	for line in txt.split("\n"):
		var p := line.find("—")
		if p > 0:
			out += "[color=#f5c542][b]" + line.substr(0, p) + \
				"[/b][/color][color=#e8ebe4]" + line.substr(p) + "[/color]\n"
		elif line.begins_with("Reglas") or line.begins_with("Extra"):
			out += "[color=#f5c542]" + line + "[/color]\n"
		else:
			out += line + "\n"
	return out


func _fill_rows(exclude: int) -> void:
	var clubs: Array = RugbyTeams.CLUBS
	for i in clubs.size():
		var b := buttons[i]
		var tag := "  ★ " + T("CAMPEÓN 2026") if i == RugbyTeams.NYG_INDEX else ""
		b.text = "%s  (%s)%s" % [clubs[i]["name"], clubs[i]["city"], tag]
		b.disabled = i == exclude
		b.modulate = Color(1, 1, 1, 0.35) if i == exclude else Color(1, 1, 1)


func _process(delta: float) -> void:
	pulse_t += delta
	# pulso sutil del logo dorado
	var glow := 0.88 + 0.12 * sin(pulse_t * 2.4)
	title_lbl.modulate = Color(1.0, 1.0, 1.0, glow)
	if step == Step.HIDDEN:
		return
	if Input.is_action_just_pressed("pause"):
		_back()
		return
	match step:
		Step.TITLE:
			var d := 0
			if Input.is_action_just_pressed("move_down"):
				d = 1
			elif Input.is_action_just_pressed("move_up"):
				d = -1
			if d != 0:
				nav_idx = (nav_idx + d + nav_btns.size()) % nav_btns.size()
				nav_btns[nav_idx].grab_focus()
		Step.HOME, Step.AWAY:
			var fo := get_viewport().gui_get_focus_owner()
			if fo != null and fo in buttons:
				var fi := buttons.find(fo)
				if fi != cursor:
					cursor = fi
					_update_preview()
			if Input.is_action_just_pressed("move_down"):
				_move_cursor(1)
			elif Input.is_action_just_pressed("move_up"):
				_move_cursor(-1)
		Step.OPTIONS:
			var od := 0
			if Input.is_action_just_pressed("move_down"):
				od = 1
			elif Input.is_action_just_pressed("move_up"):
				od = -1
			if od != 0:
				var ci := opt_btns.find(get_viewport().gui_get_focus_owner())
				ci = (ci + od + opt_btns.size()) % opt_btns.size() if ci >= 0 else 0
				opt_btns[ci].grab_focus()


func _move_cursor(delta: int) -> void:
	var n := RugbyTeams.CLUBS.size()
	var exclude := home_idx if step == Step.AWAY else -1
	var next := cursor
	for _tries in n:
		next = (next + delta + n) % n
		if next != exclude:
			break
	if next != cursor:
		cursor = next
		buttons[cursor].grab_focus()
		_update_preview()


func _update_preview() -> void:
	if preview_tex == null or cursor < 0:
		return
	var c: Dictionary = RugbyTeams.CLUBS[cursor]
	preview_tex.texture = RugbyTeams.jersey_texture(cursor)
	var stars := clampi(int(round((c["rating"] - 0.88) / 0.05)), 1, 5)
	preview_lbl.text = "%s\n%s\nRating %s" % [c["name"], c["city"],
		"★".repeat(stars) + "☆".repeat(5 - stars)]


func _back() -> void:
	match step:
		Step.HOME, Step.CONTROLS, Step.OPTIONS, Step.TABLE:
			step = Step.TITLE
		Step.AWAY:
			step = Step.HOME
			cursor = home_idx
	_update_view()


func _on_mode_pressed(m: String) -> void:
	mode = m
	result_lbl.text = ""
	step = Step.HOME
	cursor = 0
	_update_view()


func flash_result(msg: String) -> void:
	result_lbl.text = msg


func _on_controls_pressed() -> void:
	step = Step.CONTROLS
	_update_view()


func _on_options_pressed() -> void:
	step = Step.OPTIONS
	_update_view()


func _on_table_pressed() -> void:
	step = Step.TABLE
	_update_view()


func _fill_table() -> void:
	if game.tour_table.is_empty():
		table_lbl.text = "[color=#f5c542]" + 			T("Todavía no jugaste el torneo.\nElegí TORNEO URT para empezar.") + 			"[/color]"
		return
	var t := game._table_text().replace("TABLA URT — FECHA",
		T("TABLA URT —") + " " + T("FECHA"))
	if game.tour_pos < game.tour_fixture.size():
		t += "\n[color=#f5c542]" + T("Próxima fecha") + ": " + 			RugbyTeams.CLUBS[game.home_idx]["name"] + " vs " + 			RugbyTeams.CLUBS[game.tour_fixture[game.tour_pos]]["name"] + 			"[/color]"
	else:
		t += "\n[color=#f5c542]Torneo terminado[/color]"
	table_lbl.text = "[code]" + t + "[/code]"


func _opt_info(i: int) -> Array:
	var yn := [T("No"), T("Sí")]
	match i:
		0:  return [T("Duración del tiempo"), "%d min" % int(game.half_len / 60.0)]
		1:  return [T("Dificultad IA"), [T("Fácil"), T("Normal"), T("Difícil")][game.opt_difficulty]]
		2:  return [T("Horario"), {"random": T("Aleatorio"), "day": T("Día"),
			"sunset": T("Atardecer"), "night": T("Noche")}[game.opt_tod]]
		3:  return [T("Clima"), {"random": T("Aleatorio"), "clear": T("Despejado"),
			"rain": T("Lluvia")}[game.opt_weather]]
		4:  return [T("Calidad gráfica"), [T("Baja"), T("Media"), T("Alta")][game.opt_quality]]
		5:  return [T("Pantalla completa"), yn[int(game.opt_fullscreen)]]
		6:  return ["VSync", yn[int(game.opt_vsync)]]
		7:  return [T("Sonido"), yn[int(game.opt_sound)]]
		8:  return [T("Volumen"), "%d%%" % [0, 25, 50, 75, 100][game.opt_volume]]
		9:  return [T("Sprint"), T("Mantener") if not game.opt_sprint_toggle else T("Alternar")]
		10: return [T("Velocidad del juego"), "%d%%" % int(game.opt_game_speed * 100.0)]
		11: return [T("Interfaz grande"), yn[int(game.opt_ui_big)]]
		12: return [T("Idioma"), "Español" if game.opt_lang == "es" else "English"]
	return ["", ""]


func _cycle_option(i: int) -> void:
	match i:
		0:
			var lens := [120.0, 180.0, 300.0]
			game.half_len = lens[(lens.find(game.half_len) + 1) % 3]
		1:
			game.opt_difficulty = (game.opt_difficulty + 1) % 3
		2:
			var tods := ["random", "day", "sunset", "night"]
			game.opt_tod = tods[(tods.find(game.opt_tod) + 1) % 4]
		3:
			var wths := ["random", "clear", "rain"]
			game.opt_weather = wths[(wths.find(game.opt_weather) + 1) % 3]
		4:
			game.opt_quality = (game.opt_quality + 1) % 3
		5:
			game.opt_fullscreen = not game.opt_fullscreen
		6:
			game.opt_vsync = not game.opt_vsync
		7:
			game.opt_sound = not game.opt_sound
		8:
			game.opt_volume = (game.opt_volume + 1) % 5
		9:
			game.opt_sprint_toggle = not game.opt_sprint_toggle
		10:
			var spd := [1.0, 0.75, 0.5]
			game.opt_game_speed = spd[(spd.find(game.opt_game_speed) + 1) % 3]
		11:
			game.opt_ui_big = not game.opt_ui_big
		12:
			game.opt_lang = "en" if game.opt_lang == "es" else "es"
	game.save_options()
	_refresh_options()


func _refresh_options() -> void:
	for hl in opt_hdrs:
		hl.text = "— " + T(opt_hdrs[hl]) + " —"
	for i in opt_btns.size():
		var info := _opt_info(i)
		opt_btns[i].text = "%-20s  < %s >" % [info[0], info[1]]


func _on_team_hover(i: int) -> void:
	if step == Step.HOME or step == Step.AWAY:
		var exclude := home_idx if step == Step.AWAY else -1
		if i != exclude:
			cursor = i
			buttons[i].grab_focus()
			_update_preview()


func _on_team_pressed(i: int) -> void:
	match step:
		Step.HOME:
			home_idx = i
			if mode == "tournament":
				# el fixture del torneo se arma solo, no hace falta rival
				hide_menu()
				game.start_match(home_idx, -1, "tournament")
				return
			step = Step.AWAY
			cursor = 0 if i != 0 else 1
			_update_view()
		Step.AWAY:
			if i == home_idx:
				return
			hide_menu()
			game.start_match(home_idx, i, mode)
