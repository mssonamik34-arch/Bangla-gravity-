extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var elapsed := 0.0
var won := false
var hazard: Node3D

func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()

func _process(delta: float) -> void:
	if player == null:
		return
	elapsed += delta
	if is_instance_valid(hazard):
		hazard.rotation.y += delta * 1.4
	if camera:
		var target := player.global_position + Vector3(0, 7.5, 10.0)
		camera.global_position = camera.global_position.lerp(target, delta * 4.0)
		camera.look_at(player.global_position + Vector3(0, 0.5, 0), Vector3.UP)
	if not won and player.global_position.z < -17.0:
		won = true
		status_label.text = "LEVEL CLEAR!  +100 COINS"
		status_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
	if player.global_position.y < -8.0:
		player.global_position = Vector3(0, 2, 7)
		player.velocity = Vector3.ZERO
		status_label.text = "আবার চেষ্টা করো!  —  Reach the glowing goal"

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.48, 0.58, 0.78)
	environment.ambient_light_energy = 0.7
	world_env.environment = environment
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.3
	add_child(sun)

	_add_platform(Vector3(0, -0.5, 4), Vector3(9, 1, 12), Color(0.15, 0.22, 0.34))
	_add_platform(Vector3(0, -0.5, -5), Vector3(5, 1, 7), Color(0.18, 0.42, 0.55))
	_add_platform(Vector3(0, -0.5, -13), Vector3(9, 1, 9), Color(0.22, 0.32, 0.45))

	_add_platform(Vector3(0, 1.0, -2.0), Vector3(2.2, 0.35, 2.2), Color(0.95, 0.58, 0.16))
	_add_platform(Vector3(2.0, 1.6, -7.0), Vector3(2.0, 0.35, 2.0), Color(0.95, 0.58, 0.16))
	_add_platform(Vector3(-1.8, 1.0, -10.0), Vector3(2.0, 0.35, 2.0), Color(0.95, 0.58, 0.16))

	hazard = Node3D.new()
	hazard.position = Vector3(0, 0.55, -5.0)
	add_child(hazard)
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(4.2, 0.28, 0.35)
	bar.mesh = bar_mesh
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(1.0, 0.22, 0.25)
	bar.material_override = bar_mat
	hazard.add_child(bar)
	var hazard_body := StaticBody3D.new()
	hazard.add_child(hazard_body)
	var hazard_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.2, 0.35, 0.45)
	hazard_shape.shape = box
	hazard_body.add_child(hazard_shape)

	var goal := MeshInstance3D.new()
	var goal_mesh := CylinderMesh.new()
	goal_mesh.top_radius = 1.0
	goal_mesh.bottom_radius = 1.0
	goal_mesh.height = 0.18
	goal.mesh = goal_mesh
	goal.position = Vector3(0, 0.12, -16.0)
	var goal_mat := StandardMaterial3D.new()
	goal_mat.albedo_color = Color(0.15, 1.0, 0.55)
	goal_mat.emission_enabled = true
	goal_mat.emission = Color(0.05, 0.8, 0.25)
	goal.material_override = goal_mat
	add_child(goal)

func _add_platform(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.5, 7)
	player.set_script(load("res://scripts/player.gd"))
	add_child(player)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 8, 17)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(22, 20)
	panel.custom_minimum_size = Vector2(440, 90)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "BANGLA GRAVITY  •  LEVEL 01"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	status_label = Label.new()
	status_label.text = "WASD / Arrow Keys: Move     SPACE: Jump"
	status_label.add_theme_font_size_override("font_size", 15)
	column.add_child(status_label)
