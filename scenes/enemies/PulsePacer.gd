extends KinematicBody2D

# Enemy properties
var speed = 50
var gravity = 500
var velocity = Vector2()
var patrol_range = 100
var random_movement_timer = Timer.new() # Timer for random movement changes
var flip_cooldown = 0.5 # Seconds before the enemy can flip direction again
var can_flip = true
# Ensure the player is found using the group
onready var player = get_tree().get_nodes_in_group("player")[0]

# RayCast2D nodes to detect walls and ledges
onready var wall_ray = $WallRayCast
onready var ledge_ray = $LedgeRayCast

# Flip the enemy sprite when direction changes
var direction: int = 1

func _ready():
	player.connect("player_scaled", self, "_on_player_scaled")
	# Add the timer as a child of this node to ensure it gets processed
	add_child(random_movement_timer)
	random_movement_timer.wait_time = 1 # Change direction every second
	random_movement_timer.autostart = true
	random_movement_timer.connect("timeout", self, "_on_random_movement_timer_timeout")
	random_movement_timer.start()
	# Ensure that the raycasts are enabled
	wall_ray.enabled = true
	ledge_ray.enabled = true
	
	update_raycasts()

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta

	# Horizontal movement
	velocity.x = speed * direction

	# Check for walls and ledges and flip direction if needed
	if can_flip and (wall_ray.is_colliding() or (not ledge_ray.is_colliding() and is_on_floor())):
		direction *= -1 # Change direction
		can_flip = false
		$Sprite.flip_h = (direction != 1)
		# Start a cooldown timer before allowing another flip
		yield(get_tree().create_timer(flip_cooldown), "timeout")
		can_flip = true

	# Move the enemy
	velocity = move_and_slide(velocity, Vector2.UP)

	# Update the sprite's direction
	$Sprite.flip_h = (direction != 1)
	update_raycasts()

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
		# Now call the player's reduce_health function with the calculated direction
		body.reduce_health(1, knockback_direction)

