extends CanvasLayer
class_name RugbyMenu

# Menú principal: título → elegir equipo local → elegir rival → partido.
enum Step { HIDDEN, TITLE, HOME, AWAY }

var game: RugbyGame
var step := Step.HIDDEN
var cursor := 0
var home_idx := -1

var bg: ColorRect
var title_lbl: Label
var subtitle_lbl: Label
var prompt_lbl: Label
var rows: Array[Label] = []
var footer_lbl: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	bg = ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.03, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	title_lbl = _lbl(64)
	title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_lbl.custom_minimum_size.x = 1280
	title_lbl.position = Vector2(-640, 60)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))

	subtitle_lbl = _lbl(20)
	subtitle_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle_lbl.custom_minimum_size.x = 1280
	subtitle_lbl.position = Vector2(-640, 140)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))

	prompt_lbl = _lbl(30)
	prompt_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	prompt_lbl.custom_minimum_size.x = 1280
	prompt_lbl.position = Vector2(-640, 190)

	for i in RugbyTeams.CLUBS.size():
		var r := _lbl(22)
		r.set_anchors_preset(Control.PRESET_CENTER)
		r.custom_minimum_size.x = 900
		r.position = Vector2(-450, -140 + i * 32)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		rows.append(r)

	footer_lbl = _lbl(16)
	footer_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer_lbl.custom_minimum_size.x = 1280
	footer_lbl.position = Vector2(-640, -50)
	footer_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))


func _lbl(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l


func start() -> void:
	step = Step.TITLE
	visible = true
	_update_view()


func hide_menu() -> void:
	step = Step.HIDDEN
	visible = false


func _update_view() -> void:
	var clubs: Array = RugbyTeams.CLUBS
	match step:
		Step.TITLE:
			title_lbl.text = "RUGBY TUCUMANO 3D"
			subtitle_lbl.text = "Unión de Rugby de Tucumán · Edición clubes"
			prompt_lbl.text = "ENTER para jugar"
			for r in rows:
				r.visible = false
			footer_lbl.text = "15 vs 15 · reglas completas · conversión al palo estilo Rugby 25"
		Step.HOME:
			prompt_lbl.text = "ELEGÍ TU EQUIPO"
			_fill_rows(-1)
			footer_lbl.text = "↑↓ navegar · Enter confirmar · Esc volver"
		Step.AWAY:
			prompt_lbl.text = "ELEGÍ EL RIVAL — local: %s" % clubs[home_idx]["name"]
			_fill_rows(home_idx)
			footer_lbl.text = "↑↓ navegar · Enter confirmar · Esc volver"


func _fill_rows(exclude: int) -> void:
	var clubs: Array = RugbyTeams.CLUBS
	for i in clubs.size():
		var r := rows[i]
		r.visible = true
		if i == exclude:
			r.text = "      %s  (%s) — ya elegido" % [clubs[i]["name"], clubs[i]["city"]]
			r.modulate = Color(1, 1, 1, 0.35)
			continue
		var sel := i == cursor
		var prefix := "  ► " if sel else "      "
		var tag := " ★ CAMPEÓN 2026" if i == RugbyTeams.NYG_INDEX else ""
		r.text = "%s%s  (%s)%s" % [prefix, clubs[i]["name"], clubs[i]["city"], tag]
		r.modulate = Color(1, 1, 1) if not sel else clubs[i]["primary"].lightened(0.35)


func _process(_delta: float) -> void:
	if step == Step.HIDDEN:
		return
	if Input.is_action_just_pressed("move_down"):
		_move_cursor(1)
	if Input.is_action_just_pressed("move_up"):
		_move_cursor(-1)
	if Input.is_action_just_pressed("pause"):
		_back()
	if Input.is_action_just_pressed("confirm"):
		_confirm()


func _move_cursor(dir: int) -> void:
	var n := RugbyTeams.CLUBS.size()
	cursor = (cursor + dir + n) % n
	var exclude := home_idx if step == Step.AWAY else -1
	if cursor == exclude:
		cursor = (cursor + dir + n) % n
	_update_view()


func _back() -> void:
	match step:
		Step.HOME:
			step = Step.TITLE
		Step.AWAY:
			step = Step.HOME
			cursor = home_idx
	_update_view()


func _confirm() -> void:
	match step:
		Step.TITLE:
			step = Step.HOME
			cursor = 0
			_update_view()
		Step.HOME:
			home_idx = cursor
			step = Step.AWAY
			cursor = 0 if cursor != 0 else 1
			if cursor == home_idx:
				cursor = 1
			_update_view()
		Step.AWAY:
			hide_menu()
			game.start_match(home_idx, cursor)
