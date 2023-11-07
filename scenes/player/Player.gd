extends KinematicBody2D

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL
}

const SPEED = 200
const GRAVITY = 800
const JUMP_FORCE = -200
const MAX_JUMP_TIME = 0.2

var velocity = Vector2.ZERO
var current_state = PlayerState.IDLE
var animation_player: AnimationPlayer
var jump_timer = 0.0
var jump_pressed = false

func _ready():
	animation_player = $AnimationPlayer

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
		$Sprite.scale.x = sign(input_vector.x)

	velocity = move_and_slide(velocity, Vector2.UP)

func handle_animation():
	# Switch animation based on the state
	match current_state:
		PlayerState.IDLE:
			animation_player.play("idle")
		PlayerState.RUN:
			animation_player.play("run")
		PlayerState.JUMP:
			animation_player.play("jump")
		PlayerState.FALL:
			animation_player.play("fall")

func set_state(new_state):
	if new_state != current_state:
		current_state = new_state
