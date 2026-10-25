extends CanvasLayer
class_name RugbyUI

var score_lbl: Label
var clock_lbl: Label
var score_bug: PanelContainer
var sb_score: Label
var sb_clock: Label
var sb_hc: ColorRect
var sb_ac: ColorRect
var _abbr_h := ""
var _abbr_a := ""
var msg_lbl: Label
var hint_lbl: Label
var comm_lbl: Label
var comm_t := 0.0
var info_lbl: Label
var pause_lbl: Label
var pause_menu: Control
var vs_panel: CenterContainer
var vs_a: TextureRect
var vs_b: TextureRect
var vs_names: Label
var pause_btns: Array[Button] = []
var game: RugbyGame
var msg_t := 0.0
var hint_t := 0.0

# UI de conversión (estilo Rugby 25)
var conv_panel: Panel
var conv_instr: Label
var aim_needle: ColorRect
var power_fill: ColorRect

# panel de stats post-partido
var stats_panel: CenterContainer
var stats_lbl: Label


func _mk_label(size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	add_child(l)
	return l


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # los botones funcionan en pausa

	score_lbl = _mk_label(34)
	score_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	score_lbl.offset_top = 6
	score_lbl.offset_bottom = 46

	clock_lbl = _mk_label(22)
	clock_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	clock_lbl.offset_top = 46
	clock_lbl.offset_bottom = 74
	# el marcador grande queda oculto: se usa el scorebug TV
	score_lbl.visible = false
	clock_lbl.visible = false

	msg_lbl = _mk_label(48)
	msg_lbl.set_anchors_preset(Control.PRESET_CENTER)
	msg_lbl.custom_minimum_size.x = 1280
	msg_lbl.position = Vector2(-640, -80)

	hint_lbl = _mk_label(22)
	hint_lbl.set_anchors_preset(Control.PRESET_CENTER)
	hint_lbl.custom_minimum_size.x = 1280
	hint_lbl.position = Vector2(-640, 90)
	hint_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))

	pause_lbl = _mk_label(44)
	pause_lbl.set_anchors_preset(Control.PRESET_CENTER)
	pause_lbl.custom_minimum_size.x = 1280
	pause_lbl.position = Vector2(-640, -30)
	pause_lbl.text = "PAUSA"
	pause_lbl.visible = false

	info_lbl = _mk_label(15)
	info_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	info_lbl.offset_top = -34
	info_lbl.offset_bottom = -6
	info_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))

	# comentario estilo transmisión (lower-third, arriba del info)
	comm_lbl = _mk_label(17)
	comm_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	comm_lbl.offset_top = -64
	comm_lbl.offset_bottom = -40
	comm_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.9, 0.9))
	comm_lbl.modulate.a = 0.0

	_build_conversion_ui()
	_build_stats_panel()
	_build_pause_menu()
	_build_vs_panel()
	_build_scorebug()


func _build_stats_panel() -> void:
	stats_panel = CenterContainer.new()
	stats_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.04, 0.08, 0.88)
	sb.border_color = Color(0.85, 0.7, 0.2)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.content_margin_left = 40
	sb.content_margin_right = 40
	sb.content_margin_top = 28
	sb.content_margin_bottom = 28
	bg.add_theme_stylebox_override("panel", sb)
	stats_lbl = Label.new()
	stats_lbl.add_theme_font_size_override("font_size", 20)
	stats_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 0.9))
	stats_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	stats_lbl.add_theme_constant_override("outline_size", 4)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bg.add_child(stats_lbl)
	stats_panel.add_child(bg)
	stats_panel.visible = false
	add_child(stats_panel)


func show_stats(text: String) -> void:
	stats_lbl.text = text
	stats_panel.visible = true


func hide_stats() -> void:
	stats_panel.visible = false


func _build_conversion_ui() -> void:
	conv_panel = Panel.new()
	conv_panel.custom_minimum_size = Vector2(460, 130)
	conv_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	conv_panel.position = Vector2(-230, -160)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.65)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	conv_panel.add_theme_stylebox_override("panel", sb)
	add_child(conv_panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 10)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	pad.add_child(vb)
	conv_panel.add_child(pad)

	conv_instr = Label.new()
	conv_instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conv_instr.add_theme_font_size_override("font_size", 18)
	vb.add_child(conv_instr)

	var aim_lbl := Label.new()
	aim_lbl.text = "DIRECCIÓN"
	aim_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aim_lbl.add_theme_font_size_override("font_size", 13)
	vb.add_child(aim_lbl)
	var aim_bar := Panel.new()
	aim_bar.custom_minimum_size = Vector2(0, 20)
	var aim_sb := StyleBoxFlat.new()
	aim_sb.bg_color = Color(0.15, 0.15, 0.18)
	aim_sb.border_color = Color(0.4, 0.9, 0.4)
	aim_sb.border_width_left = 2
	aim_sb.border_width_right = 2
	aim_bar.add_theme_stylebox_override("panel", aim_sb)
	var center_mark := ColorRect.new()
	center_mark.color = Color(0.4, 0.9, 0.4)
	center_mark.size = Vector2(3, 20)
	center_mark.position = Vector2(205, 0)
	aim_bar.add_child(center_mark)
	aim_needle = ColorRect.new()
	aim_needle.color = Color(1.0, 0.85, 0.1)
	aim_needle.size = Vector2(10, 20)
	aim_bar.add_child(aim_needle)
	vb.add_child(aim_bar)

	var pow_lbl := Label.new()
	pow_lbl.text = "POTENCIA"
	pow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pow_lbl.add_theme_font_size_override("font_size", 13)
	vb.add_child(pow_lbl)
	var pow_bar := Panel.new()
	pow_bar.custom_minimum_size = Vector2(0, 20)
	var pow_sb := StyleBoxFlat.new()
	pow_sb.bg_color = Color(0.15, 0.15, 0.18)
	pow_bar.add_theme_stylebox_override("panel", pow_sb)
	power_fill = ColorRect.new()
	power_fill.color = Color(0.3, 0.85, 0.3)
	power_fill.size = Vector2(0, 20)
	pow_bar.add_child(power_fill)
	vb.add_child(pow_bar)

	conv_panel.visible = false


func _process(delta: float) -> void:
	if pause_menu != null and pause_menu.visible:
		var pd := 0
		if Input.is_action_just_pressed("move_down"):
			pd = 1
		elif Input.is_action_just_pressed("move_up"):
			pd = -1
		if pd != 0:
			var ci := pause_btns.find(get_viewport().gui_get_focus_owner())
			ci = (ci + pd + pause_btns.size()) % pause_btns.size() if ci >= 0 else 0
			pause_btns[ci].grab_focus()
	if comm_t > 0.0:
		comm_t -= delta
		if comm_t <= 0.0:
			comm_lbl.modulate.a = 0.0
	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0:
			msg_lbl.modulate.a = 0.0
	if hint_t > 0.0:
		hint_t -= delta
		if hint_t <= 0.0:
			hint_lbl.modulate.a = 0.0


func set_score(_name_a: String, a: int, b: int, _name_b: String) -> void:
	sb_score.text = "%s  %d — %d  %s" % [_abbr_h, a, b, _abbr_a]


func set_clock(t: String) -> void:
	sb_clock.text = t


func set_teams(h_i: int, a_i: int) -> void:
	_abbr_h = RugbyTeams.CLUBS[h_i]["abbr"]
	_abbr_a = RugbyTeams.CLUBS[a_i]["abbr"]
	sb_hc.color = RugbyTeams.CLUBS[h_i]["primary"]
	sb_ac.color = RugbyTeams.CLUBS[a_i]["primary"]


func _build_scorebug() -> void:
	score_bug = PanelContainer.new()
	score_bug.set_anchors_preset(Control.PRESET_TOP_LEFT)
	score_bug.offset_left = 14
	score_bug.offset_top = 10
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.03, 0.02, 0.82)
	sb.border_color = Color(1.0, 0.75, 0.15, 0.85)
	sb.border_width_bottom = 3
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	score_bug.add_theme_stylebox_override("panel", sb)
	add_child(score_bug)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	score_bug.add_child(vb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)
	sb_hc = ColorRect.new()
	sb_hc.custom_minimum_size = Vector2(6, 22)
	sb_hc.color = Color(0.5, 0.5, 0.5)
	hb.add_child(sb_hc)
	sb_score = Label.new()
	sb_score.add_theme_font_size_override("font_size", 24)
	sb_score.add_theme_color_override("font_color", Color(0.96, 0.96, 0.92))
	sb_score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	sb_score.add_theme_constant_override("outline_size", 5)
	sb_score.text = "—  0 — 0  —"
	hb.add_child(sb_score)
	sb_ac = ColorRect.new()
	sb_ac.custom_minimum_size = Vector2(6, 22)
	sb_ac.color = Color(0.5, 0.5, 0.5)
	hb.add_child(sb_ac)
	sb_clock = Label.new()
	sb_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sb_clock.add_theme_font_size_override("font_size", 15)
	sb_clock.add_theme_color_override("font_color", Color(0.85, 0.9, 0.8))
	vb.add_child(sb_clock)


func show_message(text: String, dur := 2.0) -> void:
	msg_lbl.text = text
	msg_lbl.modulate.a = 1.0
	msg_t = dur


func flash_hint(text: String, dur := 1.2) -> void:
	hint_lbl.text = text
	hint_lbl.modulate.a = 1.0
	hint_t = dur


# línea de comentario sutil, estilo relator de TV
func commentary(text: String, dur := 3.6) -> void:
	comm_lbl.text = text
	comm_lbl.modulate.a = 1.0
	comm_t = dur


func set_info(text: String) -> void:
	info_lbl.text = text


func set_paused(on: bool) -> void:
	pause_menu.visible = on
	if on and pause_btns.size() > 0:
		pause_btns[0].grab_focus()


func _pause_btn(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 50)
	b.add_theme_font_size_override("font_size", 24)
	var sb := func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.border_width_left = 5
		s.content_margin_left = 16
		s.corner_radius_top_left = 4
		s.corner_radius_top_right = 4
		s.corner_radius_bottom_left = 4
		s.corner_radius_bottom_right = 4
		return s
	b.add_theme_stylebox_override("normal", sb.call(Color(0.06, 0.09, 0.07, 0.95), Color(0.3, 0.4, 0.3)))
	b.add_theme_stylebox_override("hover", sb.call(Color(0.14, 0.24, 0.16), Color(1.0, 0.75, 0.15)))
	b.add_theme_stylebox_override("focus", sb.call(Color(0.14, 0.24, 0.16), Color(1.0, 0.75, 0.15)))
	b.add_theme_color_override("font_color", Color(0.9, 0.92, 0.88))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.3))
	b.add_theme_color_override("font_focus_color", Color(1.0, 0.85, 0.3))
	b.mouse_entered.connect(func(): b.grab_focus())
	return b


func _build_pause_menu() -> void:
	pause_menu = Control.new()
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	add_child(pause_menu)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	cc.add_child(vb)
	var t := Label.new()
	t.text = "PAUSA"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 52)
	t.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	t.add_theme_constant_override("outline_size", 8)
	vb.add_child(t)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vb.add_child(spacer)
	var defs := [
		["REANUDAR", func(): _unpause()],
		["REINICIAR PARTIDO", func():
			_unpause()
			game.start_match(game.home_idx, game.away_idx, game.mode)],
		["SALIR AL MENÚ", func():
			_unpause()
			game.return_to_menu()],
	]
	for d in defs:
		var b := _pause_btn(d[0])
		b.pressed.connect(d[1])
		vb.add_child(b)
		pause_btns.append(b)


func _unpause() -> void:
	get_tree().paused = false
	set_paused(false)


# ─── tarjeta VS pre-partido (estilo FIFA) ─────────────────────────────────
func _build_vs_panel() -> void:
	vs_panel = CenterContainer.new()
	vs_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	vs_panel.visible = false
	add_child(vs_panel)
	var bg := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.03, 0.02, 0.88)
	sb.border_color = Color(1.0, 0.75, 0.15, 0.8)
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.content_margin_left = 60
	sb.content_margin_right = 60
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	bg.add_theme_stylebox_override("panel", sb)
	vs_panel.add_child(bg)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	bg.add_child(vb)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 36)
	vb.add_child(hb)
	vs_a = TextureRect.new()
	vs_a.custom_minimum_size = Vector2(110, 140)
	vs_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vs_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(vs_a)
	var vl := Label.new()
	vl.text = "VS"
	vl.add_theme_font_size_override("font_size", 56)
	vl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.15))
	vl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	vl.add_theme_constant_override("outline_size", 8)
	hb.add_child(vl)
	vs_b = TextureRect.new()
	vs_b.custom_minimum_size = Vector2(110, 140)
	vs_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vs_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(vs_b)
	vs_names = Label.new()
	vs_names.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_names.add_theme_font_size_override("font_size", 26)
	vs_names.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	vb.add_child(vs_names)


func show_vs(home_i: int, away_i: int) -> void:
	vs_a.texture = RugbyTeams.jersey_texture(home_i)
	vs_b.texture = RugbyTeams.jersey_texture(away_i)
	vs_names.text = "%s  —  %s" % [RugbyTeams.CLUBS[home_i]["name"],
		RugbyTeams.CLUBS[away_i]["name"]]
	vs_panel.visible = true
	vs_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(vs_panel, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.8)
	tw.tween_property(vs_panel, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): vs_panel.visible = false)


# ─── UI de conversión ───────────────────────────────────────────────────────
func conv_show() -> void:
	conv_panel.visible = true
	conv_set_aim(0.0)
	conv_set_power(0.0)


func conv_hide() -> void:
	conv_panel.visible = false


func conv_set_aim(v: float) -> void:
	# v en [-1, 1]; barra de 420px internos
	aim_needle.position.x = (v + 1.0) * 0.5 * 400.0 + 5.0


func conv_set_power(v: float) -> void:
	power_fill.size.x = clampf(v, 0.0, 1.0) * 410.0
	power_fill.color = Color(0.9 - v * 0.6, 0.25 + v * 0.6, 0.2) if v < 0.85 else Color(0.9, 0.2, 0.15)


func conv_set_instr(t: String) -> void:
	conv_instr.text = t
