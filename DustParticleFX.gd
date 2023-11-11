extends Node2D

onready var animated_sprite = $AnimatedSprite


var velocity = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	animated_sprite.frame = randi() % 3
	animated_sprite.play("default")


func _process(delta):
	position += velocity * delta


func _on_AnimatedSprite_animation_finished():
	queue_free()
