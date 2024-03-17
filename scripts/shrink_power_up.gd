extends Area2D

var itemUsed = false

func _ready():
	PlayerEvents.player_load.connect(_respawn_item)

func _on_body_entered(body):
	if !itemUsed:
		itemUsed = true
		PlayerEvents.player_shrink.emit()
		$Sprite2D.visible = false
		$PointLight2D.enabled = false

func _respawn_item():
	itemUsed = false
	$Sprite2D.visible = true
	$PointLight2D.enabled = true
