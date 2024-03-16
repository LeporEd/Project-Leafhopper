extends Node

@onready var audio_stream_player = $Main_theme_player

func _ready():
	audio_stream_player.finished.connect(_on_loop_sound)
	_start_main_theme()

func _start_main_theme():
	audio_stream_player.play()

func _on_loop_sound():
	audio_stream_player.stream_paused = false
	audio_stream_player.play()

func _pause():
	audio_stream_player.stream_paused = true
