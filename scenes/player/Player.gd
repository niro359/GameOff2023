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
var velocity = Vector2.ZERO
var current_state = PlayerState.IDLE
var animation_player: AnimationPlayer
const MAX_JUMP_TIME = 0.2
var jump_timer = 0.0


func _ready():
	animation_player = $AnimationPlayer


func _physics_process(delta):
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
		jump_timer = 0.0
	else:
		if velocity.y < 0:
			set_state(PlayerState.JUMP)
		else:
			set_state(PlayerState.FALL)
		
		if Input.is_action_pressed("ui_up") and jump_timer < MAX_JUMP_TIME:
			velocity.y = JUMP_FORCE
			jump_timer += delta
		else:
			jump_timer = MAX_JUMP_TIME
	
	if input_vector.x == 0:
		$Sprite.scale.x = $Sprite.scale.x
	else:
		$Sprite.scale.x = sign(input_vector.x)

	velocity = move_and_slide(velocity, Vector2.UP)


func _input(event):
		 if event.is_action_pressed("ui_up"):
			 if is_on_floor():
				 velocity.y = JUMP_FORCE


func set_state(new_state):
	   if new_state != current_state:
		   current_state = new_state
		   match current_state:
			   PlayerState.IDLE:
				   animation_player.play("idle")
			   PlayerState.RUN:
				   animation_player.play("run")
			   PlayerState.JUMP:
				   animation_player.play("jump")
			   PlayerState.FALL:
				   animation_player.play("fall")
