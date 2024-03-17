extends Area2D

var endingTriggered = false

func _on_body_entered(body):
	if !endingTriggered:
		endingTriggered = true
		WorldEvents.on_game_ending.emit()
		PlayerEvents.player_deactivate_movement.emit()
		PlayerEvents.player_start_endgame_animation.emit()
