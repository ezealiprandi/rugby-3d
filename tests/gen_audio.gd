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
	print("audio generado")
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
