extends Area2D

@onready var teleportAnim = get_node("AnimationPlayer")
@onready var animSprite = get_node("Sprite2D3")

func _ready():
	animSprite.visible = false

func _on_body_entered(body):
	#PlayerEvents.player_teleport.emit(position)
	teleportAnim.play("teleport_on")
