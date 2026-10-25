const fs = require("fs");
let ok = true;
function patch(f, subs) {
  let s = fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n");
  for (const [o, n] of subs) {
    if (!s.includes(o)) { console.log("MISS in " + f + ": " + o.slice(0, 80).replace(/\n/g, "\n")); ok = false; continue; }
    s = s.split(o).join(n);
  }
  fs.writeFileSync(f, s);
}

patch("scripts/main.gd", [
// declaraciones de sonido
[`var sfx_whistle: AudioStreamPlayer
var sfx_crowd: AudioStreamPlayer
var sfx_cheer: AudioStreamPlayer`,
`var sfx_whistle: AudioStreamPlayer
var sfx_crowd: AudioStreamPlayer
var sfx_cheer: AudioStreamPlayer
var sfx_rain: AudioStreamPlayer
var sfx_steps: AudioStreamPlayer
var sfx_tackle: AudioStreamPlayer
var sfx_slide: AudioStreamPlayer
var sfx_kick: AudioStreamPlayer`],
[`	sfx_whistle = _mk_audio("res://assets/whistle.wav", -6.0)
	sfx_crowd = _mk_audio("res://assets/crowd.wav", -16.0)
	sfx_cheer = _mk_audio("res://assets/cheer.wav", -4.0)`,
`	sfx_whistle = _mk_audio("res://assets/whistle.wav", -6.0)
	sfx_crowd = _mk_audio("res://assets/crowd.wav", -16.0)
	sfx_cheer = _mk_audio("res://assets/cheer.wav", -4.0)
	sfx_rain = _mk_audio("res://assets/rain.wav", -18.0)
	sfx_steps = _mk_audio("res://assets/steps.wav", -14.0)
	sfx_tackle = _mk_audio("res://assets/tackle.wav", -8.0)
	sfx_slide = _mk_audio("res://assets/slide.wav", -9.0)
	sfx_kick = _mk_audio("res://assets/kick.wav", -6.0)`],
// lluvia ambiente en el loop
[`	if weather == "rain":
		ui.show_message("🌧 Lluvia en Tucumán — la pelota resbala", 3.0)`,
`	if weather == "rain":
		ui.show_message("🌧 Lluvia en Tucumán — la pelota resbala", 3.0)
		if sfx_rain.stream != null and not sfx_rain.playing:
			sfx_rain.play()
	elif sfx_rain.playing:
		sfx_rain.stop()`],
// pasos del jugador controlado al correr/caminar
[`		Phase.PLAY:
			clock += delta
			if settle_t > 0.0:
				settle_t -= delta
			_record_frame()`,
`		Phase.PLAY:
			clock += delta
			if settle_t > 0.0:
				settle_t -= delta
			_record_frame()
			if controlled != null and controlled.tackled <= 0.0 \
					and controlled.velocity.length() > 2.5:
				if sfx_steps.stream != null and not sfx_steps.playing:
					sfx_steps.play()
				sfx_steps.pitch_scale = \
					1.15 if controlled.velocity.length() > 8.5 else 0.9
			elif sfx_steps.playing:
				sfx_steps.stop()`],
// placaje: golpe
[`	tackler.tackled = 1.2
	carrier.tackled = 1.2`,
`	tackler.tackled = 1.2
	carrier.tackled = 1.2
	if sfx_tackle.stream != null:
		sfx_tackle.play()`],
// barrida (palomita / lance): quién tira el dive lo sabe player.gd → engancho en el placaje con dive
[`	if tackler.dive_t > 0.02 and rng.randf() < 0.1:`,
`	if tackler.dive_t > 0.02 and sfx_slide.stream != null:
		sfx_slide.play()
	if tackler.dive_t > 0.02 and rng.randf() < 0.1:`],
// patadas: kickoff, conversión, touch, dropout, patada en juego
[`	ball.linear_velocity = Vector3(diff.x / t, (diff.y + 4.9 * t * t) / t, diff.z / t)
	ball.angular_velocity = Vector3(kd, 0.0, 0.0) * 10.0
	ball.release_guard = 0.35
	ball.last_touch_team = kick_team`,
`	ball.linear_velocity = Vector3(diff.x / t, (diff.y + 4.9 * t * t) / t, diff.z / t)
	ball.angular_velocity = Vector3(kd, 0.0, 0.0) * 10.0
	ball.release_guard = 0.35
	ball.last_touch_team = kick_team
	_kick_sfx()`],
[`	ball.linear_velocity = dir * sp + Vector3(0, 7.5 + conv_power * 5.0, 0)`,
`	ball.linear_velocity = dir * sp + Vector3(0, 7.5 + conv_power * 5.0, 0)
	_kick_sfx()`],
[`	ball.linear_velocity = dir * 22.0 + Vector3(0.0, 7.5, 0.0)
	ball.angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 14.0`,
`	ball.linear_velocity = dir * 22.0 + Vector3(0.0, 7.5, 0.0)
	ball.angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 14.0
	_kick_sfx()`],
[`	ball.linear_velocity = Vector3(diff.x / t, (diff.y + 4.9 * t * t) / t, diff.z / t)
	ball.angular_velocity = Vector3(d, 0, 0) * 10.0
	ball.release_guard = 0.35
	ball.last_touch_team = drop_team`,
`	ball.linear_velocity = Vector3(diff.x / t, (diff.y + 4.9 * t * t) / t, diff.z / t)
	ball.angular_velocity = Vector3(d, 0, 0) * 10.0
	ball.release_guard = 0.35
	ball.last_touch_team = drop_team
	_kick_sfx()`],
// helper
[`func _whistle() -> void:`,
`func _kick_sfx() -> void:
	if sfx_kick.stream != null:
		sfx_kick.play()


func _whistle() -> void:`],
]);

/* palomita al try: quién zambulle también suena a barrida — en _score_try */
patch("scripts/main.gd", [
[`		scorer.try_dive_t = 1.1`,
`		scorer.try_dive_t = 1.1
		if sfx_slide.stream != null:
			sfx_slide.play()`],
]);

/* player.gd — patada en juego + barrida suenan */
patch("scripts/player.gd", [
[`	game.ball.linear_velocity = v
	game.ball.angular_velocity = Vector3(-d, 0, 0) * 8.0`,
`	game.ball.linear_velocity = v
	game.ball.angular_velocity = Vector3(-d, 0, 0) * 8.0
	game._kick_sfx()`],
[`	dive_t = 0.45
	dive_cd = 1.7`,
`	dive_t = 0.45
	dive_cd = 1.7
	if game != null and game.sfx_slide.stream != null:
		game.sfx_slide.play()`],
]);

/* menu.gd — sacar los beeps viejos */
patch("scripts/menu.gd", [
[`	sfx_tick = AudioStreamPlayer.new()
	if FileAccess.file_exists("res://assets/tick.wav"):
		sfx_tick.stream = load("res://assets/tick.wav")
		sfx_tick.volume_db = -14.0
	add_child(sfx_tick)
	sfx_confirm = AudioStreamPlayer.new()
	if FileAccess.file_exists("res://assets/confirm.wav"):
		sfx_confirm.stream = load("res://assets/confirm.wav")
		sfx_confirm.volume_db = -10.0
	add_child(sfx_confirm)`,
``],
[`# tick al enfocar, confirm al elegir
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
		sfx_confirm.play()`,
``],
[`	_wire_sounds()
`,``],
[`var sfx_tick: AudioStreamPlayer
var sfx_confirm: AudioStreamPlayer
`,``],
]);

/* ui.gd — textos con contorno para legibilidad tipo TV */
patch("scripts/ui.gd", [
[`func _lbl(size := 16) -> Label:`,
`func _lbl(size := 16) -> Label:`],
]);
