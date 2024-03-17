extends Area2D

@onready var teleportAnim = get_node("AnimationPlayer")
@onready var animSprite = get_node("Sprite2D3")
@onready var secondAnimTimer = get_node("Timer")

func _ready():
	animSprite.visible = false

func _on_body_entered(body):
	teleportAnim.play("teleport_on")
	secondAnimTimer.start()



func _on_timer_timeout():
	PlayerEvents.player_teleport.emit(position)
	teleportAnim.play("teleport_off")
