extends KinematicBody2D

var velocity = Vector2.ZERO


func _physics_process(delta):
	# Move the player
		velocity = move_and_slide(velocity, Vector2.UP)
