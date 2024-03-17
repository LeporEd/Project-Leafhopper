extends Area2D

@onready var SavedTextTimer = get_node("../SavedTextTimer")
@onready var SavedText = get_node("../SavedText")

var checkpointUsed = false

func _on_body_entered(body):
	if !checkpointUsed:
		checkpointUsed = true
		SavedTextTimer.start()
		SavedText.visible = true
		PlayerEvents.player_save.emit()

func _on_timer_timeout():
	SavedText.visible = false
