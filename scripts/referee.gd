extends Node3D
class_name RugbyReferee

# Árbitro en el campo (sigue la jugada por detrás) + 2 jueces de touch
# parados en la línea media.
var game: RugbyGame
var model: Humanoid
var move_speed := 0.0
var ref_face := 0.0


static func make_model(colors: Dictionary) -> Humanoid:
	return Humanoid.make({
		"jersey": colors.get("jersey", Color(0.1, 0.1, 0.12)),
		"jersey_tex": null,
		"trim": colors.get("trim", Color(0.95, 0.95, 0.95)),
		"shorts": colors.get("shorts", Color(0.1, 0.1, 0.12)),
		"skin": Color(0.85, 0.62, 0.47),
		"bulk": 0.95,
	})


func build_match() -> void:
	# árbitro de campo: negro con vivos blancos
	model = RugbyReferee.make_model({})
	add_child(model)

	# jueces de touch en la línea media, uno por lado
	for side in [-1.0, 1.0]:
		var tj := RugbyReferee.make_model({
			"jersey": Color(0.95, 0.75, 0.1),
			"trim": Color(0.1, 0.1, 0.12),
			"shorts": Color(0.1, 0.1, 0.12),
		})
		tj.position = Vector3(side * (RugbyField.W + 4.5), 0.0, 0.0)
		tj.rotation.y = -side * PI * 0.5
		add_child(tj)


func _process(delta: float) -> void:
	if game == null or game.ball == null or model == null:
		return
	var ball_pos := game.ball.global_position
	var d: float = float(game.attack_dir[game.ball.last_touch_team]) \
		if game.ball.last_touch_team >= 0 else 1.0
	# el árbitro se ubica detrás de la jugada y algo de costado
	var target := ball_pos + Vector3(
		signf(ball_pos.x + 1.0) * 4.0, 0.0, -d * 9.0)
	target.x = clampf(target.x, -RugbyField.W + 1.5, RugbyField.W - 1.5)
	target.z = clampf(target.z, -46.0, 46.0)
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	move_speed = lerpf(move_speed, minf(dist * 2.0, 7.0), delta * 4.0)
	if dist > 0.3:
		global_position += to.normalized() * move_speed * delta
		ref_face = atan2(to.x, to.z)
	model.animate(delta, move_speed, 7.0, 0.0, false, ref_face)
