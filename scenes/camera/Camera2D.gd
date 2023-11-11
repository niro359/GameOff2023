extends Camera2D

var target = null
var shake_intensity = 0
var shake_duration = 0
var default_zoom = Vector2(1, 1)
var target_zoom = Vector2(1, 1)
var zoom_speed = 2  # Adjust for faster or slower zoom
var debug = true

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		set_target(players[0])
	default_zoom = zoom
	target_zoom = zoom

func _process(delta):
	if debug:
		handle_debug_input(delta)
	
	if is_instance_valid(target):
		update_camera_position(target.global_position, delta)
		handle_camera_shake(delta)
		handle_smooth_zoom(delta)

	else:
		handle_target_not_valid()

func set_target(new_target):
	target = new_target

func update_camera_position(target_position, delta):
	var camera_position = global_position
	var smoothed_position = camera_position.linear_interpolate(target_position, delta * 5)
	global_position = smoothed_position

func handle_target_not_valid():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		set_target(players[0])

func handle_camera_shake(delta):
	if shake_duration > 0:
		shake_duration -= delta
		offset = Vector2(rand_range(-shake_intensity, shake_intensity), rand_range(-shake_intensity, shake_intensity))
	else:
		shake_intensity = 0
		offset = Vector2.ZERO

func start_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func set_zoom_level(zoom_level: Vector2):
	target_zoom = zoom_level

func reset_zoom():
	target_zoom = default_zoom

func handle_smooth_zoom(delta):
	zoom = zoom.linear_interpolate(target_zoom, zoom_speed * delta)

func handle_debug_input(delta):
	if Input.is_key_pressed(KEY_R):
		start_shake(2, 0.1)
	if Input.is_key_pressed(KEY_T):
		set_zoom_level(Vector2(1.5, 1.5))
	if Input.is_key_pressed(KEY_Y):
		reset_zoom()
	if Input.is_key_pressed(KEY_U):
		var enemies = get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			set_target(enemies[0])
	if Input.is_key_pressed(KEY_I):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			set_target(players[0])
