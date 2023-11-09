extends KinematicBody2D

enum States { HIDING, ACTIVE, TRANSITION, KNOCKED_BACK }
var current_state = States.HIDING
var speed = 50
var gravity = 500
var velocity = Vector2()
var patrol_range = 100
var random_movement_timer = Timer.new()
var flip_cooldown = 0.5
var can_flip = true

# Idle state properties
var idle_timer = Timer.new()
const IDLE_DURATION = 2.0

# Health and knockback properties
var max_health = 3
var health = max_health
var knockback_velocity = Vector2.ZERO
var is_knockback = false
const KNOCKBACK_TIME = 0.2
const KNOCKBACK_FORCE = Vector2(50, -150)

onready var player = get_tree().get_nodes_in_group("player")[0]
var is_player_small = false

var direction: int = 1

func _ready():
	player.connect("player_scaled", self, "_on_player_scaled")
	set_state(States.HIDING)

func _process(delta):
	match current_state:
		States.HIDING:
			handle_hiding_state(delta)
		States.ACTIVE:
			handle_active_state(delta)
		States.TRANSITION:
			handle_transition_state(delta)
		States.KNOCKED_BACK:
			handle_knockback_state(delta)


func set_state(new_state):
	current_state = new_state
	match current_state:
		States.HIDING:
			pass
			# Setup hiding state (e.g., change sprite, stop shooting)
		States.ACTIVE:
			pass
			# Setup active state (e.g., start shooting)
		States.TRANSITION:
			pass
			# Setup transition (e.g., play animation)

func handle_hiding_state(delta):
	# Apply gravity even when idle to keep grounded
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	# Logic for when in hiding state

func handle_active_state(delta):
	# Apply gravity even when idle to keep grounded
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	# Logic for when in active state (e.g., shooting projectiles)

func handle_transition_state(delta):
	# Apply gravity even when idle to keep grounded
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	# Logic for handling transitions between states

func _on_player_scaled(new_is_small):
	is_player_small = new_is_small
	if is_player_small:
		set_state(States.TRANSITION) # Transition to active state
	else:
		set_state(States.TRANSITION) # Transition to hiding state


# Enemy script
func _on_HitBox_body_entered(body):
	if body.is_in_group("player"):
		# Calculate the horizontal knockback direction based on the relative positions
		var knockback_direction = Vector2.ZERO
		knockback_direction.x = -sign(global_position.x - body.global_position.x)  # Left (-1) or Right (1)
		$Sprite.flip_h = knockback_direction.x != 1
		direction = knockback_direction.x
		# Now call the player's reduce_health function with the calculated direction
		take_damage(1,-knockback_direction)
		body.reduce_health(1, knockback_direction)


func handle_knockback_state(delta):
	# Apply gravity to the knockback
	knockback_velocity.y += gravity * delta

	# Use move_and_slide to move the Pulse Pacer
	knockback_velocity = move_and_slide(knockback_velocity, Vector2.UP)

	# If the Pulse Pacer hits the ground, transition out of knockback state
	if is_on_floor():
		current_state = States.HIDING


func apply_knockback(direction):
	current_state = States.KNOCKED_BACK
	is_knockback = true
	var vertical_force = Vector2(0, -150)
	knockback_velocity = KNOCKBACK_FORCE * direction.normalized() + vertical_force

func take_damage(amount, direction):
	health -= amount
	if health <= 0:
		# Handle the death of the pulse pacer, like deactivating it or playing an animation
		queue_free()  # Or any other logic for when health reaches zero
	else:
		apply_knockback(direction)
