extends SceneTree

# Genera los efectos de sonido del juego (sin assets externos):
#   assets/whistle.wav — silbato de árbitro
#   assets/crowd.wav   — ambiente de tribuna (loop)
#   assets/cheer.wav   — festejo de try / gol
# Uso: godot --headless --script tests/gen_audio.gd

const RATE := 22050
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 42
	DirAccess.make_dir_recursive_absolute("res://assets")
	_whistle()
	_crowd()
	_cheer()
	_rain()
	_steps()
	_tackle()
	_slide()
	_kick()
	print("audio generado")
	quit()


func _rain() -> void:
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


func _tick() -> void:
	# blip corto 0.06s para navegación de menú
	var n := int(RATE * 0.06)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := exp(-t * 60.0)
		var s := sin(TAU * 1400.0 * t) * env
		data[i] = int(clampf(128.0 + s * 100.0, 0.0, 255.0))
	_save_wav("res://assets/tick.wav", data)


func _confirm() -> void:
	# dos tonos ascendentes 0.18s para confirmar
	var n := int(RATE * 0.18)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / RATE
		var f := 880.0 if t < 0.09 else 1320.0
		var env := minf(1.0, t / 0.01) * exp(-t * 5.0)
		var s := sin(TAU * f * t) * env
		data[i] = int(clampf(128.0 + s * 95.0, 0.0, 255.0))
	_save_wav("res://assets/confirm.wav", data)
	quit()


func _save_wav(path: String, data: PackedByteArray, loop := false) -> void:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_8_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	w.save_to_wav(path)


func _whistle() -> void:
	# silbato ~0.9s: dos armónicos con vibrato, ataque rápido y release
	var n := int(RATE * 0.9)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t / 0.015) * minf(1.0, (0.9 - t) / 0.12)
		var vib := 1.0 + 0.04 * sin(TAU * 28.0 * t)
		var s := 0.6 * sin(TAU * 2500.0 * vib * t) \
			+ 0.4 * sin(TAU * 3400.0 * vib * t)
		data[i] = int(clampf(128.0 + s * env * 110.0, 0.0, 255.0))
	_save_wav("res://assets/whistle.wav", data)


func _crowd() -> void:
	# ambiente 6s en loop: ruido suavizado con oleajes lentos
	var n := int(RATE * 6.0)
	var data := PackedByteArray()
	data.resize(n)
	var acc := 0.0
	for i in n:
		var t := float(i) / RATE
		acc = acc * 0.94 + rng.randf_range(-1.0, 1.0) * 0.06
		var swell := 0.6 + 0.3 * sin(TAU * 0.11 * t) + 0.1 * sin(TAU * 0.043 * t)
		var s := acc * 8.0 * swell
		data[i] = int(clampf(128.0 + s * 30.0, 0.0, 255.0))
	_save_wav("res://assets/crowd.wav", data, true)


func _cheer() -> void:
	# festejo 2.2s: ruido con envolvente de subida/bajada
	var n := int(RATE * 2.2)
	var data := PackedByteArray()
	data.resize(n)
	var acc := 0.0
	for i in n:
		var t := float(i) / RATE
		acc = acc * 0.9 + rng.randf_range(-1.0, 1.0) * 0.1
		var env := minf(1.0, t / 0.25) * exp(-t * 1.4)
		var s := acc * 10.0 * env + rng.randf_range(-0.15, 0.15) * env
		data[i] = int(clampf(128.0 + s * 110.0, 0.0, 255.0))
	_save_wav("res://assets/cheer.wav", data)
