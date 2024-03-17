extends Node2D

@onready var game_theme = $Game_theme

func _ready():
	game_theme.finished.connect(_on_loop_sound)
	PlayerEvents.on_player_died.connect(_on_game_over)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_loop_sound():
	game_theme.stream_paused = false
	game_theme.play()

func _on_game_over():
	PlayerEvents.player_load.emit()
