extends KinematicBody2D

# At the top of the script
export (PackedScene) var ProjectileScene

enum States { ACTIVE, KNOCKED_BACK }
var current_state = States.ACTIVE
var speed = 50
var gravity = 500
var velocity = Vector2()

# Health and knockback properties
var max_health = 3
var health = max_health
var knockback_velocity = Vector2.ZERO
var is_knockback = false
const KNOCKBACK_TIME = 0.2
const KNOCKBACK_FORCE = Vector2(50, -150)

# Shooting properties
var shooting_timer = Timer.new()
const SHOOTING_INTERVAL = 1.0  # seconds between bursts
const BURST_COUNT = 3  # number of projectiles in a burst
var burst_shot_count = 0

var projectile_rotation_degrees : float = 0

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var player_ref = weakref(player)

var direction: int = 1

func _ready():
	set_state(States.ACTIVE)
	shooting_timer.wait_time = SHOOTING_INTERVAL / BURST_COUNT  # Adjust for burst rate
	shooting_timer.one_shot = false
	shooting_timer.connect("timeout", self, "_on_shooting_timer_timeout")
	add_child(shooting_timer)
	shooting_timer.start()

func _process(delta):
	match current_state:
		States.ACTIVE:
			handle_active_state(delta)
		States.KNOCKED_BACK:
			handle_knockback_state(delta)

func set_state(new_state):
	current_state = new_state
	# Additional setup for each state if needed

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

func handle_knockback_state(delta):
	# Apply gravity to the knockback
	knockback_velocity.y += gravity * delta
	knockback_velocity = move_and_slide(knockback_velocity, Vector2.UP)
	if is_on_floor():
		set_state(States.ACTIVE)

func apply_knockback(direction):
	current_state = States.KNOCKED_BACK
	is_knockback = true
	var vertical_force = Vector2(0, -150)
	knockback_velocity = KNOCKBACK_FORCE * direction.normalized() + vertical_force

func take_damage(amount, direction):
	health -= amount
	if health <= 0:
		queue_free()
	else:
		apply_knockback(direction)

func _on_shooting_timer_timeout():
	if current_state == States.ACTIVE:
		shoot_projectile()
		burst_shot_count += 1
		if burst_shot_count >= BURST_COUNT:
			burst_shot_count = 0
			shooting_timer.stop()
			yield(get_tree().create_timer(SHOOTING_INTERVAL), "timeout")  # Wait before next burst
			shooting_timer.start()  # Restart shooting

func shoot_projectile():
	var player_instance = player_ref.get_ref()
	if player_instance:
		var horizontal_direction = sign(player.global_position.x - global_position.x)
		var projectile = ProjectileScene.instance()
		projectile.global_position = global_position
		if horizontal_direction == -1:
			projectile.rotation_degrees = 0
		else:
			projectile.rotation_degrees = 180
		projectile.direction = Vector2(horizontal_direction, 0)
		get_parent().add_child(projectile)
	else:
		pass
