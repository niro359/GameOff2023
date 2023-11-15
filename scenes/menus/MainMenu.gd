extends CanvasLayer


func _on_StartButton_pressed():
	# Code to start the game
	get_tree().change_scene("res://scenes/demo/Demo.tscn")

func _on_OptionsButton_pressed():
	# Code to show options
	# This can be another scene or a popup
	pass

func _on_ExitButton_pressed():
	get_tree().quit()  # Exit the game
