extends KinematicBody2D

enum EnemyStates {
	IDLE,
	MOVING,
	KNOCKED_BACK
}

# Enemy properties
var current_state = EnemyStates.IDLE
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

# Player reference
onready var player = get_tree().get_nodes_in_group("player")[0]

# RayCast2D nodes
onready var wall_ray = $WallRayCast
onready var ledge_ray = $LedgeRayCast

var direction: int = 1

func _ready():
	player.connect("player_scaled", self, "_on_player_scaled")
	add_child(idle_timer)
	add_child(random_movement_timer)
	idle_timer.wait_time = IDLE_DURATION
	idle_timer.one_shot = true
	idle_timer.connect("timeout", self, "_on_idle_timer_timeout")
	wall_ray.enabled = true
	ledge_ray.enabled = true
	update_raycasts()

func _physics_process(delta):
	match current_state:
		EnemyStates.IDLE:
			handle_moving_state(delta)
		EnemyStates.MOVING:
			handle_moving_state(delta)
		EnemyStates.KNOCKED_BACK:
			handle_knockback_state(delta)

func handle_idle_state(delta):
	# Apply gravity even when idle to keep grounded
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)


func _on_idle_timer_timeout():
	# Decide whether to stay idle or start moving
	if randf() > 0.5:
		current_state = EnemyStates.MOVING
	else:
		idle_timer.start()  # Stay idle for another duration


func handle_moving_state(delta):
	# Apply gravity
	velocity.y += gravity * delta
	
	# Horizontal movement
	velocity.x = speed * direction

	if can_flip and (wall_ray.is_colliding() or (not ledge_ray.is_colliding() and is_on_floor())):
		direction *= -1
		can_flip = false
		$Sprite.flip_h = direction != 1
		yield(get_tree().create_timer(flip_cooldown), "timeout")
		can_flip = true
	
	velocity = move_and_slide(velocity, Vector2.UP)
	if is_on_floor() and velocity.y > 0:
		velocity.y = 0  # Reset vertical velocity when on ground
	$Sprite.flip_h = direction != 1
	update_raycasts()

func handle_knockback_state(delta):
	# Apply gravity to the knockback
	knockback_velocity.y += gravity * delta

	# Use move_and_slide to move the Pulse Pacer
	knockback_velocity = move_and_slide(knockback_velocity, Vector2.UP)

	# If the Pulse Pacer hits the ground, transition out of knockback state
	if is_on_floor():
		current_state = EnemyStates.IDLE


func apply_knockback(direction):
	current_state = EnemyStates.KNOCKED_BACK
	is_knockback = true
	var vertical_force = Vector2(0, -150)
	knockback_velocity = KNOCKBACK_FORCE * direction.normalized() + vertical_force

func _on_random_movement_timer_timeout():
	# Randomly decide whether to change direction
	if randf() > 0.5:
		direction *= -1


func _on_player_scaled(new_is_small):
	if new_is_small:
		# If the player is small, decrease the Pulse Pacer's speed and stop chasing
		speed = 50
		random_movement_timer.start()  # Make the Pulse Pacer move randomly again
	else:
		# If the player is big, increase the Pulse Pacer's speed and chase the player
		speed = 200
		random_movement_timer.stop()  # Stop random movement
		# Point the direction towards the player
		direction = sign(player.global_position.x - global_position.x)
		update_raycasts()  # Update raycasts for the new direction
		

func update_raycasts():
	# Adjust the raycast direction based on the enemy's facing direction
	wall_ray.cast_to.x = direction * abs(wall_ray.cast_to.x)
	ledge_ray.cast_to.x = direction * abs(ledge_ray.cast_to.x)


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


func take_damage(amount, direction):
	health -= amount
	if health <= 0:
		# Handle the death of the pulse pacer, like deactivating it or playing an animation
		queue_free()  # Or any other logic for when health reaches zero
	else:
		apply_knockback(direction)
