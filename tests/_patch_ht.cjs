const fs = require('fs');
const load = f => fs.readFileSync(f, 'utf8').replace(/\r\n/g, '\n');
const save = (f, s) => fs.writeFileSync(f, s.replace(/\n/g, '\r\n'));

// ============ ui.gd ============
let u = load('scripts/ui.gd');
const RU = (o, n) => {
	if (!u.includes(o)) throw new Error('U-MISS: ' + o.slice(0, 60));
	u = u.replace(o, n);
};

RU(`var stam_panel: PanelContainer
var stam_fill: ColorRect
var stam_name: Label`,
`var stam_panel: PanelContainer
var stam_fill: ColorRect
var stam_name: Label
var sb_hcard: ColorRect
var sb_acard: ColorRect
var ht_panel: PanelContainer
var ht_lbl: Label
var ht_t := 0.0`);

// tarjetas dentro del scorebug
RU(`	sb_hc = ColorRect.new()
	sb_hc.custom_minimum_size = Vector2(6, 22)
	sb_hc.color = Color(0.5, 0.5, 0.5)
	hb.add_child(sb_hc)`,
`	sb_hc = ColorRect.new()
	sb_hc.custom_minimum_size = Vector2(6, 22)
	sb_hc.color = Color(0.5, 0.5, 0.5)
	hb.add_child(sb_hc)
	sb_hcard = ColorRect.new()
	sb_hcard.custom_minimum_size = Vector2(10, 14)
	sb_hcard.visible = false
	hb.add_child(sb_hcard)`);

RU(`	sb_ac = ColorRect.new()
	sb_ac.custom_minimum_size = Vector2(6, 22)
	sb_ac.color = Color(0.5, 0.5, 0.5)
	hb.add_child(sb_ac)`,
`	sb_ac = ColorRect.new()
	sb_ac.custom_minimum_size = Vector2(6, 22)
	sb_ac.color = Color(0.5, 0.5, 0.5)
	hb.add_child(sb_ac)
	sb_acard = ColorRect.new()
	sb_acard.custom_minimum_size = Vector2(10, 14)
	sb_acard.visible = false
	hb.add_child(sb_acard)`);

// panel de stats al entretiempo
RU(`	stam_panel.visible = false
	add_child(stam_panel)`,
`	stam_panel.visible = false
	add_child(stam_panel)

	# stats del primer tiempo (abajo al centro, sobre la barra de energía)
	ht_panel = _bcast_panel()
	ht_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ht_panel.offset_left = -330
	ht_panel.offset_right = 330
	ht_panel.offset_top = -150
	ht_panel.offset_bottom = -90
	ht_lbl = Label.new()
	ht_lbl.add_theme_font_size_override("font_size", 17)
	ht_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	ht_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ht_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ht_panel.add_child(ht_lbl)
	ht_panel.visible = false
	add_child(ht_panel)`);

RU(`	if scorer_t > 0.0:`,
`	if ht_t > 0.0:
		ht_t -= delta
		if ht_t <= 0.0:
			ht_panel.visible = false
	if scorer_t > 0.0:`);

RU(`func scorer_show(p: RugbyPlayer) -> void:`,
`func card_show(team: int, is_red: bool) -> void:
	var r := sb_hcard if team == 0 else sb_acard
	r.color = Color(0.95, 0.1, 0.1) if is_red else Color(1.0, 0.85, 0.1)
	r.visible = true


func ht_show(text: String) -> void:
	ht_lbl.text = text
	ht_panel.visible = true
	ht_t = 6.0


func scorer_show(p: RugbyPlayer) -> void:`);
save('scripts/ui.gd', u);

// ============ main.gd ============
let g = load('scripts/main.gd');
const RG = (o, n) => {
	if (!g.includes(o)) throw new Error('G-MISS: ' + o.slice(0, 60));
	g = g.replace(o, n);
};

// tarjeta → icono en el scorebug + tarjeta con nombre
RG(`			if not is_red:
				pen_count[offender] = 0
			ui.show_message("¡TARJETA ROJA! %s se queda con 14 todo el partido"
				% _club_name(offender), 3.5) if is_red \
				else ui.show_message("¡TARJETA AMARILLA! %s juega con 14"
				% _club_name(offender), 3.0)`,
`			if not is_red:
				pen_count[offender] = 0
			ui.card_show(offender, is_red)
			ui.commentary("Tarjeta para #%d %s" % [card.index + 1, card.pname])
			ui.show_message("¡TARJETA ROJA! %s se queda con 14 todo el partido"
				% _club_name(offender), 3.5) if is_red \
				else ui.show_message("¡TARJETA AMARILLA! %s juega con 14"
				% _club_name(offender), 3.0)`);

// stats del 1T al entretiempo
RG(`		# ingresan los suplentes: piernas frescas en ambos equipos
		for p in players:
			p.stamina = 1.0
		ui.commentary("Movimiento en los bancos: entra sangre fresca")`,
`		# stats del primer tiempo, estilo transmisión
		var hstats := "1T — %s %d · %d %s   ·   Tries %d-%d   ·   Placajes %d-%d" % [
			RugbyTeams.CLUBS[home_idx]["abbr"], score[0], score[1],
			RugbyTeams.CLUBS[away_idx]["abbr"],
			tries_n[0], tries_n[1], tackles_n[0], tackles_n[1]]
		var htot2: float = poss_t[0] + poss_t[1]
		if htot2 > 1.0:
			hstats += "   ·   Posesión %d%%-%d%%" % [
				int(poss_t[0] / htot2 * 100), int(poss_t[1] / htot2 * 100)]
		ui.ht_show(hstats)
		# ingresan los suplentes: piernas frescas en ambos equipos
		for p in players:
			p.stamina = 1.0
		ui.commentary("Movimiento en los bancos: entra sangre fresca")`);
save('scripts/main.gd', g);
console.log('OK');
