extends CanvasLayer
class_name RugbyMenu

# Menú principal: título → elegir equipo local → elegir rival → partido.
# Hecho con contenedores + botones: funciona con mouse y teclado, y se adapta
# a cualquier resolución de ventana.
enum Step { HIDDEN, TITLE, HOME, AWAY, CONTROLS }

var game: RugbyGame
var step := Step.HIDDEN
var cursor := 0
var home_idx := -1
var mode := "friendly"

var bg: ColorRect
var title_lbl: Label
var subtitle_lbl: Label
var prompt_lbl: Label
var result_lbl: Label
var play_btn: Button
var tourney_btn: Button
var practice_btn: Button
var controls_btn: Button
var controls_lbl: Label
var grid: GridContainer
var buttons: Array[Button] = []
var footer_lbl: Label


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

	bg = ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.03, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	controls_lbl = _lbl(22)
	controls_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9))
	controls_lbl.text = """WASD / Flechas — mover
Shift — sprint
Q / E — pase a la izquierda / derecha
Espacio — pase al apoyo más cercano
F — placaje · en el ruck: intentá robar la pelota
X — sidestep (amague lateral, difícil de placar)
J — fend (quitarse el placaje)
C — grubber (patada rasante por el piso)
V — up and under (patada alta disputada)
K — patada larga · en un penal: a los palos (+3)
G — drop goal (en juego, cerca de los palos)
Espacio ×2 — conversión: dirección y potencia
Esc — pausa
R / M — revancha / menú (al final, o M en práctica)

El cono amarillo marca tu jugador: el portador en ataque,
el defensor más cercano al balón en defensa."""
	controls_lbl.visible = false
	vb.add_child(controls_lbl)

	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(grid)

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
	grid.visible = step == Step.HOME or step == Step.AWAY
	controls_lbl.visible = is_controls

	match step:
		Step.TITLE:
			title_lbl.text = "RUGBY TUCUMANO 3D"
			subtitle_lbl.text = "Unión de Rugby de Tucumán · Edición clubes"
			prompt_lbl.text = "15 vs 15 · camisetas oficiales · árbitro en cancha"
			footer_lbl.text = "Click o Enter para jugar · v3.0"
			play_btn.grab_focus()
		Step.HOME:
			prompt_lbl.text = "ELEGÍ TU EQUIPO" + \
				(" — TORNEO URT" if mode == "tournament" else "")
			footer_lbl.text = "↑↓ mover · Enter/click confirmar · Esc volver"
			_fill_rows(-1)
			buttons[cursor].grab_focus()
		Step.AWAY:
			prompt_lbl.text = "ELEGÍ EL RIVAL — tu equipo: %s" % clubs[home_idx]["name"]
			footer_lbl.text = "↑↓ mover · Enter/click confirmar · Esc volver"
			_fill_rows(home_idx)
			buttons[cursor].grab_focus()
		Step.CONTROLS:
			prompt_lbl.text = "CONTROLES"
			footer_lbl.text = "Esc volver"


func _fill_rows(exclude: int) -> void:
	var clubs: Array = RugbyTeams.CLUBS
	for i in clubs.size():
		var b := buttons[i]
		var tag := "  ★ CAMPEÓN 2026" if i == RugbyTeams.NYG_INDEX else ""
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
		if Input.is_action_just_pressed("move_down"):
			_move_cursor(2)
		elif Input.is_action_just_pressed("move_up"):
			_move_cursor(-2)
		elif Input.is_action_just_pressed("move_right"):
			_move_cursor(1)
		elif Input.is_action_just_pressed("move_left"):
			_move_cursor(-1)


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


func _back() -> void:
	match step:
		Step.HOME, Step.CONTROLS:
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


func _on_team_hover(i: int) -> void:
	if step == Step.HOME or step == Step.AWAY:
		var exclude := home_idx if step == Step.AWAY else -1
		if i != exclude:
			cursor = i
			buttons[i].grab_focus()


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
