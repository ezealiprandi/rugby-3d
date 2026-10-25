extends CanvasLayer
class_name RugbyMenu

# Menú principal: título → elegir equipo local → elegir rival → partido.
# Hecho con contenedores + botones: funciona con mouse y teclado, y se adapta
# a cualquier resolución de ventana.
enum Step { HIDDEN, TITLE, HOME, AWAY, CONTROLS, OPTIONS }

var game: RugbyGame
var step := Step.HIDDEN
var cursor := 0
var home_idx := -1
var mode := "friendly"

var bgt: TextureRect
var title_lbl: Label
var subtitle_lbl: Label
var prompt_lbl: Label
var result_lbl: Label
var play_btn: Button
var tourney_btn: Button
var practice_btn: Button
var controls_btn: Button
var options_btn: Button
var controls_lbl: Label
var opt_box: VBoxContainer
var opt_btns: Array[Button] = []
var opt_hdrs := {}          # Label -> clave de idioma
var grid: GridContainer
var sel_row: HBoxContainer
var buttons: Array[Button] = []
var footer_lbl: Label
var preview_tex: TextureRect
var preview_lbl: Label


const EN := {
	"AMISTOSO": "FRIENDLY",
	"TORNEO URT · 11 fechas": "URT TOURNAMENT · 11 rounds",
	"PRÁCTICA LIBRE": "FREE PRACTICE",
	"CONTROLES": "CONTROLS",
	"OPCIONES": "OPTIONS",
	"Unión de Rugby de Tucumán · Edición clubes": "Tucumán Rugby Union · Clubs edition",
	"15 vs 15 · camisetas oficiales · árbitro en cancha": "15 vs 15 · official kits · referee on pitch",
	"Click o Enter para jugar": "Click or Enter to play",
	"ELEGÍ TU EQUIPO": "CHOOSE YOUR TEAM",
	"ELEGÍ EL RIVAL": "CHOOSE THE OPPONENT",
	" — TORNEO URT": " — URT TOURNAMENT",
	" — tu equipo: ": " — your team: ",
	"↑↓ mover · Enter/click confirmar · Esc volver": "↑↓ move · Enter/click confirm · Esc back",
	"Enter/click cambia el valor · Esc guarda y vuelve": "Enter/click changes · Esc saves & back",
	"Esc volver": "Esc back",
	"CAMPEÓN 2026": "2026 CHAMPION",
	"PARTIDO": "MATCH", "GRÁFICOS": "GRAPHICS", "AUDIO": "AUDIO",
	"ACCESIBILIDAD": "ACCESSIBILITY", "IDIOMA": "LANGUAGE",
	"Duración del tiempo": "Match half length",
	"Dificultad IA": "AI difficulty",
	"Horario": "Time of day", "Clima": "Weather",
	"Aleatorio": "Random", "Día": "Day", "Atardecer": "Sunset", "Noche": "Night",
	"Despejado": "Clear", "Lluvia": "Rain",
	"Calidad gráfica": "Graphics quality", "Baja": "Low", "Media": "Medium", "Alta": "High",
	"Pantalla completa": "Fullscreen", "VSync": "VSync",
	"Sonido": "Sound", "Volumen": "Volume", "Sí": "Yes", "No": "No",
	"Sprint": "Sprint", "Mantener": "Hold", "Alternar": "Toggle",
	"Velocidad del juego": "Game speed", "Interfaz grande": "Big UI",
	"Idioma": "Language", "Español": "Español", "Inglés": "English",
}


func T(txt: String) -> String:
	if game != null and game.opt_lang == "en":
		return EN.get(txt, txt)
	return txt


func _mode_button(text: String, bg_c: Color, border_c: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 50)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_stylebox_override("normal", _btn_style(bg_c, border_c))
	b.add_theme_stylebox_override("hover",
		_btn_style(bg_c.lightened(0.25), border_c.lightened(0.35)))
	b.add_theme_stylebox_override("pressed",
		_btn_style(bg_c.darkened(0.25), border_c.lightened(0.35)))
	b.add_theme_stylebox_override("focus",
		_btn_style(bg_c.lightened(0.25), Color(1.0, 0.85, 0.2)))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b


func _lbl(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


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

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	center.add_child(vb)

	title_lbl = _lbl(60)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
	vb.add_child(title_lbl)

	# franja dorada de acento bajo el título
	var accent := ColorRect.new()
	accent.custom_minimum_size = Vector2(460, 4)
	accent.color = Color(1.0, 0.75, 0.15, 0.9)
	accent.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(accent)

	subtitle_lbl = _lbl(20)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
	vb.add_child(subtitle_lbl)

	result_lbl = _lbl(22)
	result_lbl.add_theme_color_override("font_color", Color(0.5, 0.95, 0.5))
	result_lbl.visible = false
	vb.add_child(result_lbl)

	prompt_lbl = _lbl(28)
	vb.add_child(prompt_lbl)

	play_btn = _mode_button("AMISTOSO", Color(0.1, 0.4, 0.18), Color(0.4, 0.9, 0.4))
	play_btn.pressed.connect(func(): _on_mode_pressed("friendly"))
	vb.add_child(play_btn)

	tourney_btn = _mode_button("TORNEO URT · 11 fechas", Color(0.35, 0.25, 0.05), Color(0.9, 0.75, 0.2))
	tourney_btn.pressed.connect(func(): _on_mode_pressed("tournament"))
	vb.add_child(tourney_btn)

	practice_btn = _mode_button("PRÁCTICA LIBRE", Color(0.15, 0.18, 0.3), Color(0.5, 0.6, 0.9))
	practice_btn.pressed.connect(func(): _on_mode_pressed("practice"))
	vb.add_child(practice_btn)

	controls_btn = _mode_button("CONTROLES", Color(0.15, 0.18, 0.3), Color(0.5, 0.6, 0.9))
	controls_btn.pressed.connect(_on_controls_pressed)
	vb.add_child(controls_btn)

	options_btn = _mode_button("OPCIONES", Color(0.22, 0.16, 0.3), Color(0.7, 0.55, 0.95))
	options_btn.pressed.connect(_on_options_pressed)
	vb.add_child(options_btn)

	# filas de opciones (ciclan valor con Enter/click)
	opt_box = VBoxContainer.new()
	opt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	opt_box.add_theme_constant_override("separation", 8)
	opt_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	opt_box.visible = false
	vb.add_child(opt_box)
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
			opt_box.add_child(hl)
			opt_hdrs[hl] = spec
		else:
			var ob := Button.new()
			ob.custom_minimum_size = Vector2(480, 36)
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
	controls_lbl = _lbl(22)
	controls_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9))
	# (texto ES/EN se asigna en _update_view)
# (texto ES/EN se asigna en _update_view)
	controls_lbl.visible = false
	vb.add_child(controls_lbl)

	sel_row = HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 24)
	sel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sel_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(sel_row)

	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sel_row.add_child(grid)

	# vista previa del club enfocado: camiseta grande + datos
	var pv := VBoxContainer.new()
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.add_theme_constant_override("separation", 8)
	pv.custom_minimum_size = Vector2(190, 0)
	sel_row.add_child(pv)
	preview_tex = TextureRect.new()
	preview_tex.custom_minimum_size = Vector2(150, 190)
	preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pv.add_child(preview_tex)
	preview_lbl = _lbl(18)
	preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.6))
	pv.add_child(preview_lbl)

	var clubs: Array = RugbyTeams.CLUBS
	for i in clubs.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(430, 44)
		b.add_theme_font_size_override("font_size", 19)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_ALL
		b.icon = RugbyTeams.jersey_texture(i)
		b.expand_icon = true
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

	footer_lbl = _lbl(16)
	footer_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	vb.add_child(footer_lbl)

	# franja decorativa con los 12 colores de club
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 6)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(strip)
	for c in RugbyTeams.CLUBS:
		var r := ColorRect.new()
		r.color = c["primary"]
		r.custom_minimum_size = Vector2(28, 9)
		strip.add_child(r)


func start() -> void:
	step = Step.TITLE
	visible = true
	_update_view()


func hide_menu() -> void:
	step = Step.HIDDEN
	visible = false


func _update_view() -> void:
	var clubs: Array = RugbyTeams.CLUBS
	var is_title := step == Step.TITLE
	var is_controls := step == Step.CONTROLS
	title_lbl.visible = is_title
	subtitle_lbl.visible = is_title
	result_lbl.visible = is_title and result_lbl.text != ""
	play_btn.visible = is_title
	tourney_btn.visible = is_title
	practice_btn.visible = is_title
	controls_btn.visible = is_title
	options_btn.visible = is_title
	opt_box.visible = step == Step.OPTIONS
	sel_row.visible = step == Step.HOME or step == Step.AWAY
	controls_lbl.visible = is_controls

	match step:
		Step.TITLE:
			title_lbl.text = "RUGBY TUCUMANO 3D"
			subtitle_lbl.text = T("Unión de Rugby de Tucumán · Edición clubes")
			prompt_lbl.text = T("15 vs 15 · camisetas oficiales · árbitro en cancha")
			footer_lbl.text = T("Click o Enter para jugar") + " · v4.0"
			play_btn.text = T("AMISTOSO")
			tourney_btn.text = T("TORNEO URT · 11 fechas")
			practice_btn.text = T("PRÁCTICA LIBRE")
			controls_btn.text = T("CONTROLES")
			options_btn.text = T("OPCIONES")
			play_btn.grab_focus()
		Step.HOME:
			prompt_lbl.text = T("ELEGÍ TU EQUIPO") + \
				(T(" — TORNEO URT") if mode == "tournament" else "")
			footer_lbl.text = T("↑↓ mover · Enter/click confirmar · Esc volver")
			_fill_rows(-1)
			buttons[cursor].grab_focus()
			_update_preview()
		Step.AWAY:
			prompt_lbl.text = T("ELEGÍ EL RIVAL") + T(" — tu equipo: ") + clubs[home_idx]["name"]
			footer_lbl.text = T("↑↓ mover · Enter/click confirmar · Esc volver")
			_fill_rows(home_idx)
			buttons[cursor].grab_focus()
			_update_preview()
		Step.CONTROLS:
			prompt_lbl.text = T("CONTROLES")
			controls_lbl.text = CONTROLS_EN if game.opt_lang == "en" else CONTROLS_ES
			footer_lbl.text = T("Esc volver")
		Step.OPTIONS:
			prompt_lbl.text = T("OPCIONES")
			footer_lbl.text = T("Enter/click cambia el valor · Esc guarda y vuelve")
			_refresh_options()
			opt_btns[0].grab_focus()


func _fill_rows(exclude: int) -> void:
	var clubs: Array = RugbyTeams.CLUBS
	for i in clubs.size():
		var b := buttons[i]
		var tag := "  ★ " + T("CAMPEÓN 2026") if i == RugbyTeams.NYG_INDEX else ""
		b.text = "%s  (%s)%s" % [clubs[i]["name"], clubs[i]["city"], tag]
		b.disabled = i == exclude
		b.modulate = Color(1, 1, 1, 0.4) if i == exclude else Color(1, 1, 1)


func _process(_delta: float) -> void:
	if step == Step.HIDDEN:
		return
	if Input.is_action_just_pressed("pause"):
		_back()
		return
	if step == Step.HOME or step == Step.AWAY:
		var fo := get_viewport().gui_get_focus_owner()
		if fo != null and fo in buttons:
			var fi := buttons.find(fo)
			if fi != cursor:
				cursor = fi
				_update_preview()
		if Input.is_action_just_pressed("move_down"):
			_move_cursor(2)
		elif Input.is_action_just_pressed("move_up"):
			_move_cursor(-2)
		elif Input.is_action_just_pressed("move_right"):
			_move_cursor(1)
		elif Input.is_action_just_pressed("move_left"):
			_move_cursor(-1)
	elif step == Step.OPTIONS:
		var d := 0
		if Input.is_action_just_pressed("move_down"):
			d = 1
		elif Input.is_action_just_pressed("move_up"):
			d = -1
		if d != 0:
			var ci := opt_btns.find(get_viewport().gui_get_focus_owner())
			ci = (ci + d + opt_btns.size()) % opt_btns.size() if ci >= 0 else 0
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
		Step.HOME, Step.CONTROLS, Step.OPTIONS:
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

Reglas extra: placaje alto y "no soltó" = penal ·
atrapar una patada rival en tus 22 = marca
K — patada larga · en un penal: a los palos (+3)
G — drop goal (en juego, cerca de los palos)
Espacio ×2 — conversión: dirección y potencia
Esc — pausa
R / M — revancha / menú (al final, o M en práctica)

El cono amarillo marca tu jugador: el portador en ataque,
el defensor más cercano al balón en defensa."""

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

Extra rules: high tackle and "not releasing" = penalty ·
catching a rival kick inside your 22 = mark
K — long kick · on a penalty: kick at goal (+3)
G — drop goal (in open play, near the posts)
Space ×2 — conversion: direction and power
Esc — pause
R / M — rematch / menu (at the end, or M in practice)

The yellow cone marks your player: the ball carrier in attack,
the nearest defender to the ball in defence."""


func _on_options_pressed() -> void:
	step = Step.OPTIONS
	_update_view()


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
