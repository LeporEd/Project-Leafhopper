extends AnimatableBody2D

func _ready():
	WorldEvents.on_game_ending.connect(_start_frog)

func _start_frog():
	$AnimationPlayer.play("frogWalking")
	$Timer.start()

func _on_timer_timeout():
	$AnimationPlayer.play("frogeating")
