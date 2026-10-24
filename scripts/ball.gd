extends RigidBody3D
class_name RugbyBall

var game: RugbyGame
var carrier: RugbyPlayer = null
var release_guard := 0.0
var last_touch_team := -1


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	mass = 0.45
	continuous_cd = true
	linear_damp = 0.1
	angular_damp = 0.7
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.5
	pm.friction = 0.9
	physics_material_override = pm

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.17
	cap.height = 0.44
	cs.shape = cap
	cs.rotation.x = PI / 2.0
	add_child(cs)

	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.17
	sm.height = 0.36
	mi.mesh = sm
	mi.rotation.x = PI / 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.36, 0.18)
	mat.roughness = 0.85
	mi.material_override = mat
	add_child(mi)
	freeze = true


func _physics_process(delta: float) -> void:
	if release_guard > 0.0:
		release_guard -= delta
	if carrier != null:
		global_position = carrier.carry_point()


func can_pickup() -> bool:
	return carrier == null and release_guard <= 0.0


func set_carrier(p: RugbyPlayer) -> void:
	release()
	carrier = p
	last_touch_team = p.team
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func release() -> void:
	if carrier != null:
		last_touch_team = carrier.team
	carrier = null
	freeze = false
	sleeping = false


func throw_to(target: RugbyPlayer, thrower: RugbyPlayer) -> void:
	release()
	release_guard = 0.2
	last_touch_team = thrower.team
	global_position = thrower.carry_point()
	var aim: Vector3 = target.global_position + target.velocity * 0.3 + Vector3(0, 0.9, 0) - global_position
	var flat := Vector2(aim.x, aim.z).length()
	var t := clampf(flat / 16.0, 0.22, 0.95)
	linear_velocity = Vector3(aim.x / t, (aim.y + 4.9 * t * t) / t + 0.5, aim.z / t)
	angular_velocity = linear_velocity.normalized() * 18.0


func kicked(kicker: RugbyPlayer, dir: Vector3) -> void:
	release()
	release_guard = 0.3
	last_touch_team = kicker.team
	global_position = kicker.carry_point()
	linear_velocity = dir * 21.0 + Vector3(0, 8.5, 0)
	angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 14.0
