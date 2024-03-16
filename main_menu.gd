extends Control

func _on_button_start_pressed():
	MainTheme._pause()
	get_tree().change_scene_to_file("res://world.tscn")


func _on_button_options_pressed():
	get_tree().change_scene_to_file("res://options.tscn")


func _on_button_credits_pressed():
	get_tree().change_scene_to_file("res://credits.tscn")


func _on_button_quit_pressed():
	get_tree().quit()
