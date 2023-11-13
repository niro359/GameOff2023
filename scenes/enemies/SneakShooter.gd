extends KinematicBody2D

# At the top of the script
export (PackedScene) var ProjectileScene

enum States { HIDING, ACTIVE, TRANSITION, KNOCKED_BACK }
var current_state = States.HIDING
var speed = 50
var gravity = 500
var velocity = Vector2()
var patrol_range = 100
var random_movement_timer = Timer.new()
var flip_cooldown = 0.5
var can_flip = true


# Health and knockback properties
var max_health = 3
var health = max_health
var knockback_velocity = Vector2.ZERO
var is_knockback = false
const KNOCKBACK_TIME = 0.2
const KNOCKBACK_FORCE = Vector2(50, -150)

# Active state properties
var shooting_timer = Timer.new()
const SHOOTING_INTERVAL = 1.0  # seconds between shots
var projectile_rotation_degrees : float = 0
const SAME_LEVEL_THRESHOLD = 100  # pixels, adjust as needed

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var player_ref = weakref(player)
var is_player_small = false

var direction: int = 1

func _ready():
	player.connect("player_scaled", self, "_on_player_scaled")
	set_state(States.ACTIVE)
	# Existing setup
	shooting_timer.wait_time = SHOOTING_INTERVAL
	shooting_timer.one_shot = false
	shooting_timer.connect("timeout", self, "_on_shooting_timer_timeout")
	add_child(shooting_timer)

func _process(delta):
	var player_instance = player_ref.get_ref()
	if player_instance:
		match current_state:
			States.HIDING:
				handle_hiding_state(delta)
			States.ACTIVE:
				handle_active_state(delta)
			States.TRANSITION:
				handle_transition_state(delta)
			States.KNOCKED_BACK:
				handle_knockback_state(delta)
	else:
		# Player does not exist or has been freed
		pass


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
	# Apply gravity
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)

	# Stop shooting
	if shooting_timer.time_left > 0:
		shooting_timer.stop()


func handle_active_state(delta):
	# Apply gravity
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	var player_instance = player_ref.get_ref()
	if player_instance:
		# Flip the sprite based on player position
		if player.global_position.x < global_position.x:
			$Sprite.flip_h = true  # Player is to the left
		else:
			$Sprite.flip_h = false  # Player is to the right

	# Check if the player is on the same level
	var vertical_distance = abs(player.global_position.y - global_position.y)
	if vertical_distance <= SAME_LEVEL_THRESHOLD:
		# Start shooting if not already started
		if shooting_timer.time_left == 0:
			shooting_timer.start()
	else:
		# Stop shooting if the player is not on the same level
		if shooting_timer.time_left > 0:
			shooting_timer.stop()




func handle_transition_state(delta):
	# Apply gravity
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)

	# Transition logic
	if is_player_small:
		# Transition to active if player is small
		shooting_timer.start()
		set_state(States.ACTIVE)
	else:
		# Transition to hiding if player is big
		shooting_timer.stop()
		set_state(States.HIDING)


func _on_player_scaled(new_is_small):
	is_player_small = new_is_small
	# Trigger transition state whenever player size changes
	set_state(States.TRANSITION)



# Enemy script
func _on_HitBox_body_entered(body):
	if body.is_in_group("player"):
		# Calculate the horizontal knockback direction based on the relative positions
		var knockback_direction = Vector2.ZERO
		knockback_direction.x = -sign(global_position.x - body.global_position.x)  # Left (-1) or Right (1)
		# Now call the player's reduce_health function with the calculated direction
		body.reduce_health(1, knockback_direction)


func handle_knockback_state(delta):
	# Apply gravity to the knockback
	knockback_velocity.y += gravity * delta

	# Use move_and_slide to move the Sneak Shooter
	knockback_velocity = move_and_slide(knockback_velocity, Vector2.UP)

	# Check if the Sneak Shooter hits the ground
	if is_on_floor():
		if player.is_small:
			set_state(States.ACTIVE)
		else:
			set_state(States.HIDING)


func apply_knockback(direction):
	current_state = States.KNOCKED_BACK
	$Sprite.flip_h = direction.x != 1
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


func _on_shooting_timer_timeout():
	var player_instance = player_ref.get_ref()
	if player_instance:
		if current_state == States.ACTIVE:
			# Determine the horizontal direction towards the player
			var horizontal_direction = sign(player.global_position.x - global_position.x)
			var projectile = ProjectileScene.instance()
			projectile.global_position = global_position
			if horizontal_direction == -1:
				projectile_rotation_degrees = 0
			elif horizontal_direction == 1:
				projectile_rotation_degrees = 180
			projectile.rotation_degrees = projectile_rotation_degrees
			projectile.direction = Vector2(horizontal_direction, 0)

			get_parent().add_child(projectile)
	else:
		pass
