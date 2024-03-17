extends Area2D



func _on_body_entered(body):
	WorldEvents.on_game_ending.emit()
