extends Camera3D
class_name RugbyCam

# Cámara tipo retransmisión que sigue el balón. En el menú orbita el estadio
# y durante la conversión se coloca detrás del pateador.
var game: RugbyGame
var sz := 0.0
var sx := 0.0
var orbit := 0.0
var override_active := false
var override_pos := Vector3.ZERO
var override_look := Vector3.ZERO


func _ready() -> void:
	current = true
	fov = 52.0


func set_override(pos: Vector3, look: Vector3) -> void:
	override_active = true
	override_pos = pos
	override_look = look


func clear_override() -> void:
	override_active = false


func _process(delta: float) -> void:
	if game == null or game.ball == null:
		return
	if game.phase == RugbyGame.Phase.MENU:
		orbit += delta * 0.1
		global_position = Vector3(sin(orbit) * 62.0, 34.0, cos(orbit) * 62.0)
		look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
		return
	if override_active:
		global_position = override_pos
		look_at(override_look, Vector3.UP)
		return
	# replay del try: cámara baja y cerca, estilo broadcast
	if game.phase == RugbyGame.Phase.REPLAY:
		var bp2 := game.ball.global_position
		var tz2 := clampf(bp2.z, -46.0, 46.0)
		var tx2 := clampf(bp2.x, -24.0, 24.0) * 0.4
		sz = lerpf(sz, tz2, minf(1.0, delta * 4.5))
		sx = lerpf(sx, tx2, minf(1.0, delta * 4.5))
		global_position = Vector3(-30.0 + sx, 17.0, sz)
		look_at(Vector3(3.0 + sx, 0.8, sz), Vector3.UP)
		return
	var bp := game.ball.global_position
	var tz := clampf(bp.z, -46.0, 46.0)
	var tx := clampf(bp.x, -24.0, 24.0) * 0.4
	var k := minf(1.0, delta * 3.5)
	sz = lerpf(sz, tz, k)
	sx = lerpf(sx, tx, k)
	global_position = Vector3(-64.0 + sx, 48.0, sz)
	look_at(Vector3(5.0 + sx, 0.0, sz), Vector3.UP)
