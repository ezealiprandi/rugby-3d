extends Camera3D
class_name RugbyCam

# Cámara tipo retransmisión: lateral elevada que sigue el balón a lo largo del campo.
var game: RugbyGame
var sz := 0.0
var sx := 0.0


func _ready() -> void:
	current = true
	fov = 52.0


func _process(delta: float) -> void:
	if game == null or game.ball == null:
		return
	var bp := game.ball.global_position
	var tz := clampf(bp.z, -44.0, 44.0)
	var tx := clampf(bp.x, -22.0, 22.0) * 0.4
	var k := minf(1.0, delta * 3.5)
	sz = lerpf(sz, tz, k)
	sx = lerpf(sx, tx, k)
	global_position = Vector3(-56.0 + sx, 40.0, sz)
	look_at(Vector3(4.0 + sx, 0.0, sz), Vector3.UP)
