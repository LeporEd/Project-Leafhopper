extends Area2D

func _on_body_entered(body):
	PlayerEvents.player_save.emit()
