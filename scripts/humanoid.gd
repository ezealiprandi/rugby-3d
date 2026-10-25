extends Node3D
class_name Humanoid

# Modelo humanoide articulado por código (piernas/brazos con pivotes,
# torso con textura de camiseta, cabeza) + animación procedural de carrera.
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var bob_t := 0.0


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


static func _capsule(parent: Node3D, r: float, h: float, y: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	mi.mesh = m
	mi.position.y = y
	mi.material_override = mat
	parent.add_child(mi)
	return mi


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


# opts: jersey_tex (Texture2D o null), jersey (Color), trim, shorts, skin, bulk, number
static func make(opts: Dictionary) -> Humanoid:
	var h := Humanoid.new()
	h._build(opts)
	return h


func _build(opts: Dictionary) -> void:
	var bulk: float = opts.get("bulk", 1.0)
	var skin_mat := Humanoid._mat(opts["skin"])
	var trim_mat := Humanoid._mat(opts["trim"])
	var shorts_mat := Humanoid._mat(opts["shorts"])

	var jersey_mat := StandardMaterial3D.new()
	if opts.get("jersey_tex") != null:
		jersey_mat.albedo_texture = opts["jersey_tex"]
	else:
		jersey_mat.albedo_color = opts["jersey"]
	jersey_mat.roughness = 0.9

	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.13 * bulk, 0.98, 0.0)
		add_child(leg)
		Humanoid._capsule(leg, 0.1, 0.62, -0.4, skin_mat)
		Humanoid._capsule(leg, 0.105, 0.22, -0.66, trim_mat)
		Humanoid._box(leg, Vector3(0.2, 0.1, 0.3), Vector3(0, -0.9, 0.05),
			Humanoid._mat(Color(0.15, 0.15, 0.15)))
		if side < 0.0:
			leg_l = leg
		else:
			leg_r = leg

	Humanoid._box(self, Vector3(0.42 * bulk, 0.3, 0.32 * bulk), Vector3(0, 1.02, 0), shorts_mat)

	# torso con la textura de camiseta
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.48 * bulk, 0.62, 0.3 * bulk)
	torso.mesh = tm
	torso.position.y = 1.38
	torso.material_override = jersey_mat
	add_child(torso)

	for side in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * (0.28 * bulk + 0.08), 1.6, 0.0)
		add_child(arm)
		Humanoid._capsule(arm, 0.085, 0.5, -0.28, jersey_mat)
		Humanoid._capsule(arm, 0.075, 0.2, -0.58, skin_mat)
		if side < 0.0:
			arm_l = arm
		else:
			arm_r = arm

	Humanoid._capsule(self, 0.14, 0.3, 1.88, skin_mat)

	# número en la espalda
	if opts.get("number", 0) > 0:
		var n := Label3D.new()
		n.text = str(opts["number"])
		n.font_size = 96
		n.pixel_size = 0.004
		var trim_c: Color = opts["trim"]
		n.modulate = trim_c if trim_c.get_luminance() > 0.3 else trim_c.lightened(0.6)
		n.outline_size = 8
		n.outline_modulate = Color(0.08, 0.08, 0.08) if trim_c.get_luminance() > 0.5 \
			else Color(0.92, 0.92, 0.92)
		n.rotation.y = PI
		n.position = Vector3(0.0, 1.42, -0.17 * bulk)
		add_child(n)


func animate(delta: float, h_speed: float, sprint_speed: float,
		tackled: float, has_ball: bool, facing_y: float) -> void:
	bob_t += delta * (5.0 + h_speed * 0.9)
	var run := clampf(h_speed / sprint_speed, 0.0, 1.0)
	if tackled > 0.0:
		rotation.x = lerpf(rotation.x, -1.4, delta * 8.0)
		position.y = lerpf(position.y, -0.7, delta * 8.0)
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.0, delta * 6.0)
		leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.0, delta * 6.0)
		arm_l.rotation.x = lerpf(arm_l.rotation.x, 0.0, delta * 6.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, 0.0, delta * 6.0)
		return
	rotation.x = lerpf(rotation.x, run * 0.16, delta * 8.0)
	position.y = lerpf(position.y, 0.0, delta * 8.0) + absf(sin(bob_t)) * 0.05 * run
	var swing := sin(bob_t) * (0.85 * run)
	leg_l.rotation.x = swing
	leg_r.rotation.x = -swing
	arm_l.rotation.x = -swing * 0.7
	arm_r.rotation.x = swing * 0.7
	if has_ball:
		arm_l.rotation.x = lerpf(arm_l.rotation.x, -1.1, delta * 10.0)
		arm_r.rotation.x = lerpf(arm_r.rotation.x, -1.1, delta * 10.0)
	if h_speed > 0.4:
		rotation.y = lerp_angle(rotation.y, facing_y, delta * 10.0)
