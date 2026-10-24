extends CanvasLayer
class_name RugbyUI

var score_lbl: Label
var clock_lbl: Label
var msg_lbl: Label
var hint_lbl: Label
var info_lbl: Label
var pause_lbl: Label
var msg_t := 0.0
var hint_t := 0.0


func _mk_label(size: int, bold := false) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(4, size / 6))
	add_child(l)
	return l


func _ready() -> void:
	layer = 10

	score_lbl = _mk_label(34)
	score_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	score_lbl.offset_top = 6
	score_lbl.offset_bottom = 46

	clock_lbl = _mk_label(22)
	clock_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	clock_lbl.offset_top = 46
	clock_lbl.offset_bottom = 74

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


func _process(delta: float) -> void:
	if msg_t > 0.0:
		msg_t -= delta
		if msg_t <= 0.0:
			msg_lbl.modulate.a = 0.0
	if hint_t > 0.0:
		hint_t -= delta
		if hint_t <= 0.0:
			hint_lbl.modulate.a = 0.0


func set_score(name_a: String, a: int, b: int, name_b: String) -> void:
	score_lbl.text = "%s  %d  —  %d  %s" % [name_a, a, b, name_b]


func set_clock(t: String) -> void:
	clock_lbl.text = t


func show_message(text: String, dur := 2.0) -> void:
	msg_lbl.text = text
	msg_lbl.modulate.a = 1.0
	msg_t = dur


func flash_hint(text: String, dur := 1.2) -> void:
	hint_lbl.text = text
	hint_lbl.modulate.a = 1.0
	hint_t = dur


func set_info(text: String) -> void:
	info_lbl.text = text


func set_paused(on: bool) -> void:
	pause_lbl.visible = on
