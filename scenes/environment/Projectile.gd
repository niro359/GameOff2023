extends KinematicBody2D  # or Area2D based on your needs

onready var lifetime_timer = $LifetimeTimer  # Assuming you've added a Timer node named "LifetimeTimer"
onready var collision_shape = $Area2D


var speed = 100
var direction : Vector2 = Vector2(-1, 0)  # Default direction (facing left)

func _ready():
	$AnimatedSprite.frame = 0
	$AnimatedSprite.play("default")
	# Rotate the sprite to face the direction of movement
#	var angle = direction.angle()
#	rotation = -angle
	lifetime_timer.start(3)  # 3 seconds lifetime, adjust as needed
	lifetime_timer.connect("timeout", self, "on_lifetime_timer_timeout")


func _physics_process(delta):
	var collision = move_and_collide(direction.normalized() * speed * delta)
	if collision:
		if collision.collider.is_in_group("solid"):
			destroy()



# Add this function to handle the timeout signal
func on_lifetime_timer_timeout():
	destroy()


func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):  # Assuming you've added the player to a group named "Player"
		var knockback_direction = Vector2.ZERO
		knockback_direction.x = -sign(global_position.x - body.global_position.x)  # Left (-1) or Right (1)
		body.reduce_health(1, knockback_direction)
		destroy()


func destroy():
	queue_free()
