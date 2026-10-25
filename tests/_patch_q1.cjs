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

// ═══ 1. gen_audio.gd — quitar tick/confirm, agregar lluvia, pasos, tackle, barrida, patada
patch("tests/gen_audio.gd", [
[`	_whistle()
	_crowd()
	_cheer()
	_tick()
	_confirm()
	print("audio generado")`,
`	_whistle()
	_crowd()
	_cheer()
	_rain()
	_steps()
	_tackle()
	_slide()
	_kick()
	print("audio generado")`],
[`func _tick() -> void:`,
`func _rain() -> void:
	# lluvia: ruido blanco apenas filtrado, loop 4s
	var n := int(RATE * 4.0)
	var data := PackedByteArray()
	data.resize(n)
	var acc := 0.0
	for i in n:
		var t := float(i) / RATE
		acc = acc * 0.75 + rng.randf_range(-1.0, 1.0) * 0.25
		var hiss := rng.randf_range(-0.35, 0.35)
		var s := acc * 4.0 + hiss
		# fundido en los bordes para un loop sin clic
		var env := minf(1.0, minf(t, 4.0 - t) / 0.15)
		data[i] = int(clampf(128.0 + s * env * 26.0, 0.0, 255.0))
	_save_wav("res://assets/rain.wav", data, true)


func _steps() -> void:
	# pasos corriendo sobre pasto: 4 pisadas sordas por segundo, loop 1s
	var n := int(RATE * 1.0)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / RATE
		var ph := fmod(t * 4.0, 1.0)
		var env := exp(-ph * 22.0)
		var thud := sin(TAU * (95.0 - ph * 30.0) * t * 4.0) * env
		var grass := rng.randf_range(-0.5, 0.5) * env * 0.5
		data[i] = int(clampf(128.0 + (thud + grass) * 60.0, 0.0, 255.0))
	_save_wav("res://assets/steps.wav", data, true)


func _tackle() -> void:
	# impacto de placaje: golpe grave + ruido corto
	var n := int(RATE * 0.35)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 14.0)
		var thud := sin(TAU * (110.0 - t * 160.0) * t) * env
		var pad := rng.randf_range(-1.0, 1.0) * exp(-t * 30.0) * 0.6
		data[i] = int(clampf(128.0 + (thud + pad) * 90.0, 0.0, 255.0))
	_save_wav("res://assets/tackle.wav", data)


func _slide() -> void:
	# barrida sobre el pasto: ruido con barrido de frecuencia descendente
	var n := int(RATE * 0.45)
	var data := PackedByteArray()
	data.resize(n)
	var acc := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := 0.9 - t * 0.9   # filtro cada vez más cerrado
		acc = acc * k + rng.randf_range(-1.0, 1.0) * (1.0 - k)
		var env := minf(1.0, t / 0.03) * exp(-t * 4.0)
		data[i] = int(clampf(128.0 + acc * env * 120.0, 0.0, 255.0))
	_save_wav("res://assets/slide.wav", data)


func _kick() -> void:
	# impacto del botín con la pelota: golpe seco medio-grave
	var n := int(RATE * 0.18)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 24.0)
		var thud := sin(TAU * (160.0 - t * 400.0) * t) * env
		var snap := rng.randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.8
		data[i] = int(clampf(128.0 + (thud + snap) * 85.0, 0.0, 255.0))
	_save_wav("res://assets/kick.wav", data)


func _tick() -> void:`],
]);
