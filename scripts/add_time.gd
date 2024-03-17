extends Area2D

var timeAdded = false

func _on_body_entered(body):
	if !timeAdded: 
		timeAdded = true
		PlayerEvents.timer_substract.emit(30)
