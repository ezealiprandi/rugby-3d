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
	if game.phase == RugbyGame.Phase.MENU or game.phase == RugbyGame.Phase.PRESENT:
		orbit += delta * 0.1
		global_position = Vector3(sin(orbit) * 62.0, 34.0, cos(orbit) * 62.0)
		look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
		return
	if override_active:
		global_position = override_pos
		look_at(override_look, Vector3.UP)
		return
	# replay del try: la cámara orbita y desciende alrededor de la jugada
	if game.phase == RugbyGame.Phase.REPLAY:
		var bp2 := game.ball.global_position
		var t := clampf(float(game.replay_i) /
			maxf(1.0, float(game.replay_buf.size())), 0.0, 1.0)
		var ang := lerpf(-2.3, -0.85, t)               # barrido ~83°
		var dist := lerpf(27.0, 18.0, t)               # se acerca
		var h := lerpf(16.0, 7.5, t)                   # y baja
		var tgt := bp2 + Vector3(sin(ang) * dist, h, cos(ang) * dist)
		global_position = global_position.lerp(tgt, minf(1.0, delta * 5.0))
		look_at(bp2 + Vector3(0.0, 1.0, 0.0), Vector3.UP)
		return
	var bp := game.ball.global_position
	var tz := clampf(bp.z, -46.0, 46.0)
	var tx := clampf(bp.x, -24.0, 24.0) * 0.4
	var k := minf(1.0, delta * 3.5)
	sz = lerpf(sz, tz, k)
	sx = lerpf(sx, tx, k)
	var mode := clampi(game.opt_camera, 0, 3)
	var tgt: Vector3
	var look: Vector3
	if mode == 3:                          # cámara "detrás" estilo Rugby 25
		tgt = Vector3(sx * 0.5, 21.0, sz + 30.0)
		look = Vector3(sx * 0.5, 0.0, sz - 12.0)
	else:
		var cam_cfg := [Vector2(-64.0, 48.0), Vector2(-46.0, 27.0),
			Vector2(-84.0, 64.0)]
		var cc: Vector2 = cam_cfg[mode]
		tgt = Vector3(cc.x + sx, cc.y, sz)
		look = Vector3(5.0 + sx, 0.0, sz)
	global_position = global_position.lerp(tgt, minf(1.0, delta * 3.0))
	look_at(look, Vector3.UP)
