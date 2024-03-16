extends Control

@onready var audio_stream_player = $AudioStreamPlayer

func _ready():
	audio_stream_player.finished.connect(_on_loop_sound)
	pass

func _process(delta):
	pass

func _on_loop_sound():
	audio_stream_player.stream_paused = false
	audio_stream_player.play()

func _on_button_start_pressed():
	get_tree().change_scene_to_file("res://world.tscn")


func _on_button_options_pressed():
	pass # Replace with function body.


func _on_button_credits_pressed():
	pass # Replace with function body.


func _on_button_quit_pressed():
	get_tree().quit()
