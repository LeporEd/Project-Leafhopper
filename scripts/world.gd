extends Node2D

@onready var game_theme = $Game_theme

func _ready():
	game_theme.finished.connect(_on_loop_sound)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
		# Debug
	if Input.is_action_just_pressed("ui_text_backspace"):
		PlayerEvents.hit_player.emit(25)
	pass

func _on_loop_sound():
	game_theme.stream_paused = false
	game_theme.play()
