extends AnimatableBody2D

func _ready():
	WorldEvents.on_game_ending.connect(_start_frog)
	$Label.position.y = -100
	$Label2.position.y = -100

func _start_frog():
	$AnimationPlayer.play("frogWalking")
	$Timer.start()
	$Timer2.start()

func _on_timer_timeout():
	$AnimationPlayer.play("frogeating")


func _on_timer_2_timeout():
	$AnimationPlayer2.play("playEndtext")
	$Timer3.start()


func _on_timer_3_timeout():
	MainTheme._start_main_theme()
	get_tree().change_scene_to_file("res://credits.tscn")
