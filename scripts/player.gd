extends CharacterBody3D

@export var move_speed: float = 7.0
@export var jump_velocity: float = 7.5
var gravity: float = 20.0
var visual: MeshInstance3D
var double_jump_unlocked := false
var jumps_used := 0

func _ready() -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.48
	capsule.height = 1.65
	visual = MeshInstance3D.new()
	visual.mesh = capsule
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.78, 0.95)
	material.metallic = 0.12
	material.roughness = 0.3
	visual.material_override = material
	visual.position.y = 0.85
	add_child(visual)

	var shape := CollisionShape3D.new()
	var capsule_shape := CapsuleShape3D.new()
	capsule_shape.radius = 0.48
	capsule_shape.height = 1.65
	shape.shape = capsule_shape
	shape.position.y = 0.85
	add_child(shape)

func _physics_process(delta: float) -> void:
	if is_on_floor():
		jumps_used = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			jumps_used = 1
	elif Input.is_action_just_pressed("jump") and double_jump_unlocked and jumps_used < 2:
		velocity.y = jump_velocity * 0.9
		jumps_used += 1

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	if direction.length() > 0.05:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), delta * 10.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.5)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * delta * 2.5)

	move_and_slide()
