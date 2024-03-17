extends Control

@onready var player = $"../../"

func _on_button_resume_pressed():
	player._pause_menu()

func _on_button_main_menu_pressed():
	MainTheme._start_main_theme()
	Engine.time_scale = 1
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_button_quit_pressed():
	get_tree().quit()
