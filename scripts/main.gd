extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var elapsed := 0.0
var won := false
var hazard: Node3D
var level_number := 1
var total_coins := 0
var best_level := 1
var next_button: Button
var goal_z := -17.0
var double_jump_unlocked := false
var network_peer: ENetMultiplayerPeer
var remote_players: Dictionary = {}
var address_input: LineEdit
var network_status: Label

func _ready() -> void:
	_load_progress()
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	if double_jump_unlocked:
		player.double_jump_unlocked = true

func _process(delta: float) -> void:
	if player == null:
		return
	elapsed += delta
	_update_network(delta)
	if is_instance_valid(hazard):
		hazard.rotation.y += delta * (1.0 + float(level_number) * 0.025)
	if camera:
		var target := player.global_position + Vector3(0, 7.5, 10.0)
		camera.global_position = camera.global_position.lerp(target, delta * 4.0)
		camera.look_at(player.global_position + Vector3(0, 0.5, 0), Vector3.UP)
	if not won and player.global_position.z < goal_z:
		won = true
		var time_bonus := maxi(0, 60 - int(elapsed))
		var reward := 100 + time_bonus
		total_coins += reward
		best_level = max(best_level, min(level_number + 1, 100))
		_save_progress()
		status_label.text = "LEVEL CLEAR!  +%d COINS  |  Total: %d" % [reward, total_coins]
		status_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
		next_button.visible = level_number < 100
		if level_number >= 100:
			status_label.text = "YOU COMPLETED ALL 100 LEVELS!  Coins: %d" % total_coins
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
	# Generate extra stepping stones as difficulty increases.
	var extra_steps := mini(2 + int(level_number / 8), 14)
	for i in range(extra_steps):
		var step_z := -1.0 - float(i) * 0.92
		var side := 1.0 if (i + level_number) % 2 == 0 else -1.0
		var step_x := side * (1.0 + float((i * 3 + level_number) % 3) * 0.55)
		var step_y := 1.0 + float((i + level_number) % 3) * 0.28
		_add_platform(Vector3(step_x, step_y, step_z), Vector3(1.25, 0.28, 1.25), Color(0.25 + float(level_number % 5) * 0.1, 0.65, 0.9))

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
	panel.custom_minimum_size = Vector2(560, 245)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "BANGLA GRAVITY  •  LEVEL %03d / 100" % level_number
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	status_label = Label.new()
	status_label.text = "WASD / Arrow Keys: Move     SPACE: Jump"
	status_label.add_theme_font_size_override("font_size", 15)
	column.add_child(status_label)
	status_label.text = "Coins: %d  |  Best unlocked: %d" % [total_coins, best_level]
	var actions := HBoxContainer.new()
	column.add_child(actions)
	var level_picker := OptionButton.new()
	for unlocked in range(1, best_level + 1):
		level_picker.add_item("Level %03d" % unlocked)
	level_picker.select(level_number - 1)
	level_picker.item_selected.connect(_select_level)
	actions.add_child(level_picker)
	var restart_button := Button.new()
	restart_button.text = "Restart"
	restart_button.pressed.connect(_restart_level)
	actions.add_child(restart_button)
	next_button = Button.new()
	next_button.text = "Next Level  →"
	next_button.visible = false
	next_button.pressed.connect(_next_level)
	actions.add_child(next_button)
	var shop_button := Button.new()
	shop_button.text = "Unlock Double Jump (250)"
	shop_button.pressed.connect(_buy_double_jump)
	column.add_child(shop_button)
	var net_row := HBoxContainer.new()
	column.add_child(net_row)
	address_input = LineEdit.new()
	address_input.placeholder_text = "Host IP (e.g. 192.168.1.5)"
	address_input.custom_minimum_size = Vector2(230, 38)
	net_row.add_child(address_input)
	var host_button := Button.new()
	host_button.text = "Host LAN"
	host_button.pressed.connect(_host_game)
	net_row.add_child(host_button)
	var join_button := Button.new()
	join_button.text = "Join"
	join_button.pressed.connect(_join_game)
	net_row.add_child(join_button)
	network_status = Label.new()
	network_status.text = "Offline mode • LAN multiplayer available"
	column.add_child(network_status)
	_build_touch_controls(layer)

func _build_touch_controls(layer: CanvasLayer) -> void:
	if not OS.has_feature("mobile") and not DisplayServer.is_touchscreen_available():
		return

	var screen_size := get_viewport().get_visible_rect().size
	_add_touch_button(layer, "◀", "move_left", Vector2(28, screen_size.y - 112), Vector2(76, 76))
	_add_touch_button(layer, "▶", "move_right", Vector2(196, screen_size.y - 112), Vector2(76, 76))
	_add_touch_button(layer, "▲", "move_forward", Vector2(112, screen_size.y - 196), Vector2(76, 76))
	_add_touch_button(layer, "▼", "move_back", Vector2(112, screen_size.y - 112), Vector2(76, 76))
	_add_touch_button(layer, "JUMP", "jump", Vector2(screen_size.x - 142, screen_size.y - 150), Vector2(112, 112))

func _add_touch_button(layer: CanvasLayer, caption: String, action: String, pos: Vector2, button_size: Vector2) -> void:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.custom_minimum_size = button_size
	button.size = button_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22 if caption != "JUMP" else 18)
	button.modulate = Color(1.0, 1.0, 1.0, 0.82)
	button.button_down.connect(Input.action_press.bind(action))
	button.button_up.connect(Input.action_release.bind(action))
	layer.add_child(button)


func _load_progress() -> void:
	var save := ConfigFile.new()
	if save.load("user://progress.cfg") == OK:
		level_number = clampi(int(save.get_value("progress", "level", 1)), 1, 100)
		best_level = clampi(int(save.get_value("progress", "unlocked", 1)), 1, 100)
		total_coins = maxi(0, int(save.get_value("progress", "coins", 0)))
		double_jump_unlocked = bool(save.get_value("abilities", "double_jump", false))
	level_number = mini(level_number, best_level)

func _save_progress() -> void:
	var save := ConfigFile.new()
	save.set_value("progress", "level", level_number)
	save.set_value("progress", "unlocked", best_level)
	save.set_value("progress", "coins", total_coins)
	save.set_value("abilities", "double_jump", double_jump_unlocked)
	save.save("user://progress.cfg")

func _restart_level() -> void:
	get_tree().reload_current_scene()

func _next_level() -> void:
	if level_number >= 100 or not won:
		return
	level_number += 1
	var save := ConfigFile.new()
	save.set_value("progress", "level", level_number)
	save.set_value("progress", "unlocked", best_level)
	save.set_value("progress", "coins", total_coins)
	save.save("user://progress.cfg")
	get_tree().reload_current_scene()

func _select_level(index: int) -> void:
	var requested_level := index + 1
	if requested_level < 1 or requested_level > best_level:
		return
	level_number = requested_level
	_save_progress()
	get_tree().reload_current_scene()


func _buy_double_jump() -> void:
	if double_jump_unlocked:
		status_label.text = "Double Jump already unlocked!"
		return
	if total_coins < 250:
		status_label.text = "Need 250 coins to unlock Double Jump."
		return
	total_coins -= 250
	double_jump_unlocked = true
	player.double_jump_unlocked = true
	_save_progress()
	status_label.text = "DOUBLE JUMP UNLOCKED!  Coins: %d" % total_coins

func _host_game() -> void:
	network_peer = ENetMultiplayerPeer.new()
	var error := network_peer.create_server(8910, 4)
	if error != OK:
		network_status.text = "Host failed: %s" % error_string(error)
		return
	multiplayer.multiplayer_peer = network_peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	network_status.text = "Hosting LAN on port 8910 • Share your local IP"

func _join_game() -> void:
	var address := address_input.text.strip_edges()
	if address.is_empty():
		network_status.text = "Enter the host device's IP address."
		return
	network_peer = ENetMultiplayerPeer.new()
	var error := network_peer.create_client(address, 8910)
	if error != OK:
		network_status.text = "Join failed: %s" % error_string(error)
		return
	multiplayer.multiplayer_peer = network_peer
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	network_status.text = "Connecting to %s..." % address

func _on_connected_to_server() -> void:
	network_status.text = "Connected! LAN multiplayer active."

func _on_connection_failed() -> void:
	network_status.text = "Connection failed. Check IP and same Wi-Fi."

func _on_peer_connected(peer_id: int) -> void:
	network_status.text = "Player %d joined." % peer_id

func _on_peer_disconnected(peer_id: int) -> void:
	if remote_players.has(peer_id):
		remote_players[peer_id].queue_free()
		remote_players.erase(peer_id)
	network_status.text = "Player %d left." % peer_id

func _update_network(_delta: float) -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return
	if multiplayer.is_server():
		rpc("_receive_player_position", multiplayer.get_unique_id(), player.global_position)
	else:
		rpc_id(1, "_relay_player_position", multiplayer.get_unique_id(), player.global_position)

@rpc("any_peer", "call_remote", "unreliable")
func _relay_player_position(peer_id: int, position: Vector3) -> void:
	if multiplayer.is_server():
		rpc("_receive_player_position", peer_id, position)

@rpc("authority", "call_remote", "unreliable")
func _receive_player_position(peer_id: int, position: Vector3) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	if not remote_players.has(peer_id):
		var avatar := MeshInstance3D.new()
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.48
		mesh.height = 1.65
		avatar.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.55, 0.18)
		avatar.material_override = material
		add_child(avatar)
		remote_players[peer_id] = avatar
	remote_players[peer_id].global_position = position
