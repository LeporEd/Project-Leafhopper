extends Area2D

var endingTriggered = false

func _on_body_entered(body):
	if !endingTriggered:
		endingTriggered = true
		WorldEvents.on_game_ending.emit()
