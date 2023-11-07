extends KinematicBody2D

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL
}

const SPEED = 125
const GRAVITY = 800
const JUMP_FORCE = -200
const MAX_JUMP_TIME = 0.2
const MAX_SCALE_CHARGES = 3  # The maximum number of scale changes the player can have

var velocity = Vector2.ZERO
var current_state = PlayerState.IDLE
var jump_timer = 0.0
var jump_pressed = false
var is_small = true # A flag to check the player's current size state
var scale_charges = MAX_SCALE_CHARGES  # The current number of scale changes available


onready var small_sprite = $SmallSprite
onready var small_collision = $SmallCollision
onready var big_sprite = $BigSprite
onready var big_collision = $BigCollision

func _ready():
	small_sprite.visible = true
	small_collision.disabled = false
	big_sprite.visible = false
	big_collision.disabled = true


func _physics_process(delta):
	handle_input(delta) # Separated input handling to its own function
	handle_movement(delta) # Separated movement logic to its own function
	handle_animation() # Separated animation handling to its own function


func handle_input(delta):
	# Check for jump input
	if Input.is_action_just_pressed("ui_up"):
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


func set_state(new_state):
	if new_state != current_state:
		current_state = new_state


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

		# Assuming the pivot point is at the bottom of the sprite,
		# you need to check the space above the player. Adjust the y-offset
		# according to the difference in height between the small and big shapes.
		var offset_y = small_collision.shape.extents.y - big_collision.shape.extents.y
		query_parameters.transform.origin = global_position + Vector2(0, offset_y)

		# Exclude the player's own collision shape from the query
		query_parameters.exclude = [self, small_collision, big_collision]

		# Perform the overlap check
		var result = space_state.intersect_shape(query_parameters)
		# If there's a collision with anything other than the player, don't grow
		if result.size() > 0:
			print("Not enough space to grow")
			return # Do not change scale if there's a collision

	# If there's enough room or if shrinking, proceed with scaling
	is_small = !is_small
	velocity.y = JUMP_FORCE  # Half of the regular jump force for a small hop
	scale_charges -= 1  # Consume a charge
	update_collision_and_visibility()

func update_collision_and_visibility():
	# Update the visibility and collision shapes based on the new size
	big_sprite.visible = !is_small
	small_sprite.visible = is_small
	big_collision.disabled = is_small
	small_collision.disabled = !is_small
	# Optionally, adjust the position slightly to prevent any embedding into the ground


func replenish_scale_charge(amount: int = 1):
	scale_charges = min(scale_charges + amount, MAX_SCALE_CHARGES)
	# You can update the UI or notify the player here if needed
