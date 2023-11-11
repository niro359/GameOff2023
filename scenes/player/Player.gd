extends KinematicBody2D

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	KNOCKBACK
}

# Define a dictionary to map states to text
var state_descriptions = {
	PlayerState.IDLE: "Idle",
	PlayerState.RUN: "Run",
	PlayerState.JUMP: "Jump",
	PlayerState.FALL: "Fall",
	PlayerState.KNOCKBACK: "KnockBack"
}

const SPEED = 75
const GRAVITY = 800
const JUMP_FORCE = -175
const MAX_JUMP_TIME = 0.2
const MAX_SCALE_CHARGES = 3  # The maximum number of scale changes the player can have
const ONE_WAY_PLATFORM_LAYER_BIT = 1
var drop_through_timer = null

var velocity = Vector2.ZERO
var current_state = PlayerState.IDLE
var jump_timer = 0.0
var jump_pressed = false
var is_small = true # A flag to check the player's current size state
var scale_charges = MAX_SCALE_CHARGES  # The current number of scale changes available
var current_sprite: AnimatedSprite

var invincibility_duration = 1.0 # Seconds the player is invincible after being hit
var is_invincible = false
var invincibility_timer = Timer.new() # Timer to track invincibility duration
# Add a new timer for the flicker effect
var flicker_timer = Timer.new()
# Additional player properties for flickering effect
var flicker_duration = 0.1  # Duration between flickers

# Variables to store the visibility state of sprites
var was_small_sprite_visible = true
var was_big_sprite_visible = false

# Knockback and invincibility properties
var knockback_strength = Vector2(200, -150)
var is_knockback = false
var knockback_timer = Timer.new() # Handles the duration of the knockback

# Player default stats
var max_health = 3
var health = max_health

var camera_last_position = Vector2()

onready var small_sprite = $SmallSprite
onready var small_collision = $SmallCollision
onready var big_sprite = $BigSprite
onready var big_collision = $BigCollision
onready var debug_label = get_node("/root/Demo/CanvasLayer/DebugLabel")

signal player_scaled(is_small)

func _ready():
	small_sprite.visible = true
	small_collision.disabled = false
	big_sprite.visible = false
	big_collision.disabled = true
	
	add_child(invincibility_timer)
	invincibility_timer.connect("timeout", self, "_on_invincibility_timer_timeout")
	
	add_child(knockback_timer)
	knockback_timer.connect("timeout", self, "_on_knockback_timer_timeout")
	
	add_child(flicker_timer)
	flicker_timer.wait_time = flicker_duration
	flicker_timer.connect("timeout", self, "_on_flicker_timer_timeout")
	
	# Logic to drop through one-way platforms
	if is_on_floor() and Input.is_action_just_pressed("ui_down"):
		drop_through_one_way_platform()
	
	update_debug_text()

func _physics_process(delta):
	handle_input(delta)  # Handle inputs only if not in KNOCKBACK state

	if current_state == PlayerState.KNOCKBACK:
		# Apply gravity manually
		velocity.y += GRAVITY * delta

		# Check if the player is still in the air
		if not is_on_floor():
			# Apply air drag or deceleration to the horizontal knockback velocity
			velocity.x = lerp(velocity.x, 0, 0.01)  # Adjust the factor as needed
		
		# Move the player
		velocity = move_and_slide(velocity, Vector2.UP)

	else:
		# Apply regular movement logic if not in KNOCKBACK state
		handle_movement(delta)
		handle_animation()
	
	update_debug_text()


func update_debug_text():
	var state_text = state_descriptions[current_state]
	debug_label.text = "State: %s\nHealth: %d/%d\nScale Charges: %d/%d" % [state_text, health, max_health, scale_charges, MAX_SCALE_CHARGES]


func handle_input(delta):
	# Check for jump input
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		jump_pressed = true
	elif Input.is_action_just_released("ui_up"):
		jump_pressed = false
		jump_timer = MAX_JUMP_TIME # Prevent additional jumping when falling
	# Check for scale input
	if Input.is_action_just_pressed("ui_scale"):
		toggle_scale()
	# Debug Replenish Charges
	if Input.is_action_just_pressed("debug_replenish"):
		replenish_scale_charge()
	# Drop through one-way platforms
	if is_on_floor() and Input.is_action_just_pressed("ui_down"):
		drop_through_one_way_platform()


func handle_movement(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector = input_vector.normalized()

	velocity.x = input_vector.x * SPEED
	velocity.y += GRAVITY * delta

	if is_on_floor():
		if input_vector.x != 0:
			set_state(PlayerState.RUN)
		else:
			set_state(PlayerState.IDLE)

		if jump_pressed:
			velocity.y = JUMP_FORCE
			jump_timer = 0.0

	else:
		if velocity.y < 0:
			set_state(PlayerState.JUMP)
		else:
			set_state(PlayerState.FALL)

		if jump_pressed and jump_timer < MAX_JUMP_TIME:
			velocity.y = JUMP_FORCE
			jump_timer += delta
			
	# Flip sprite based on movement direction
	if input_vector.x != 0:
		small_sprite.scale.x = sign(input_vector.x)
		big_sprite.scale.x = small_sprite.scale.x

	velocity = move_and_slide(velocity, Vector2.UP)


func drop_through_one_way_platform():
	# Disable collision with the one-way platform layer
	set_collision_mask_bit(ONE_WAY_PLATFORM_LAYER_BIT, false)

	# Use a timer to re-enable collision after a short delay
	drop_through_timer = Timer.new()
	drop_through_timer.wait_time = 0.2  # Adjust the delay as needed
	drop_through_timer.one_shot = true
	add_child(drop_through_timer)
	drop_through_timer.start()
	drop_through_timer.connect("timeout", self, "_on_drop_through_timer_timeout")


func _on_drop_through_timer_timeout():
	# Re-enable collision with the one-way platform layer
	set_collision_mask_bit(ONE_WAY_PLATFORM_LAYER_BIT, true)
	# Remove the timer using the stored reference
	if drop_through_timer:
		drop_through_timer.queue_free()
		drop_through_timer = null  # Reset the reference



func handle_animation():
	# Switch animation based on the state
	match current_state:
		PlayerState.IDLE:
			small_sprite.play("idle")
		PlayerState.RUN:
			small_sprite.play("run")
		PlayerState.JUMP:
			small_sprite.play("jump")
		PlayerState.FALL:
			small_sprite.play("fall")
		PlayerState.KNOCKBACK:
			small_sprite.play("hurt")


func toggle_scale():
	if scale_charges <= 0:
		print("No scale charges left")
		return  # Do not change scale if there are no charges left

	# Only check for space if the player is small and trying to grow
	if is_small:
		var space_state = get_world_2d().direct_space_state
		var query_parameters = Physics2DShapeQueryParameters.new()
		
		query_parameters.set_shape(big_collision.shape)
		query_parameters.transform = big_collision.global_transform

		var offset_y = small_collision.shape.extents.y - big_collision.shape.extents.y
		query_parameters.transform.origin = global_position + Vector2(0, offset_y)

		query_parameters.exclude = [self, small_collision, big_collision]

		var result = space_state.intersect_shape(query_parameters)
		
		for collision_info in result:
			if collision_info.collider and collision_info.collider.is_in_group("OneWayPlatforms"):
				continue  # It's a one-way platform; allow scaling
			else:
				print("Not enough space to grow")
				return # Collision with non-one-way-platform

	# If there's enough room or if shrinking, proceed with scaling
	is_small = !is_small
	scale_charges -= 1  # Consume a charge
	update_collision_and_visibility()
	velocity.y = JUMP_FORCE
	emit_signal("player_scaled", is_small)


func update_collision_and_visibility():
	# Update the visibility and collision shapes based on the new size
	big_sprite.visible = !is_small
	small_sprite.visible = is_small
	big_collision.disabled = is_small
	small_collision.disabled = !is_small
	# Make sure the sprite visibility matches the scale state
	was_small_sprite_visible = is_small
	was_big_sprite_visible = !is_small



func replenish_scale_charge(amount: int = 1):
	scale_charges = min(scale_charges + amount, MAX_SCALE_CHARGES)
	# You can update the UI or notify the player here if needed


func reduce_health(amount, knockback_direction):
	if is_invincible or is_knockback:
		return  # Ignore if the player is currently invincible or in knockback

	health -= amount
	health = max(health, 0)  # Prevent health from going below 0
	update_debug_text()
	
	if health > 0:
		is_knockback = true
		# Use the direction provided to set the horizontal knockback
		velocity.x = knockback_strength.x * knockback_direction.x
		# Use a set upward force for the vertical knockback
		velocity.y = knockback_strength.y
		set_state(PlayerState.KNOCKBACK)
		knockback_timer.start(0.2)  # Shorter duration for the knockback effect
		make_invincible()
	else:
		die()  # Handle the player's death


func make_invincible():
	is_invincible = true
	# Store the current visibility of the sprites before knockback
	was_small_sprite_visible = small_sprite.visible
	was_big_sprite_visible = big_sprite.visible
	flicker_timer.start()  # Start flickering effect
	invincibility_timer.start()  # Start invincibility duration

func _on_invincibility_timer_timeout():
	is_invincible = false
	flicker_timer.stop()  # Stop flickering effect
	_reset_sprite_visibility()  # Ensure sprite visibility is reset


func _on_flicker_timer_timeout():
	# Toggle the visibility of the sprite that was visible before knockback
	if was_small_sprite_visible:
		small_sprite.visible = !small_sprite.visible
	if was_big_sprite_visible:
		big_sprite.visible = !big_sprite.visible


func _reset_sprite_visibility():
	# Reset the visibility of the sprites based on their state before knockback
	small_sprite.visible = was_small_sprite_visible
	big_sprite.visible = was_big_sprite_visible


func _on_knockback_timer_timeout():
	is_knockback = false
	if current_state == PlayerState.KNOCKBACK:
		set_state(PlayerState.IDLE)  # Return to IDLE or any other appropriate state

func set_state(new_state):
	current_state = new_state
	if new_state != PlayerState.KNOCKBACK:
		is_knockback = false


func die():
	# Check if the Camera2D is still a valid node
	if $Camera2D:
		# Store the current camera position
		camera_last_position = $Camera2D.global_position

		# Detach the Camera2D from the player
		var camera = $Camera2D
		camera.get_parent().remove_child(camera)

		# Immediately set the camera position after detaching
		camera.global_position = camera_last_position

		# Add the camera to the root node
		get_tree().get_root().add_child(camera)

	# Then free the player
	queue_free()

