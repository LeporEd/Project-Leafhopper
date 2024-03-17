extends RigidBody2D

@onready var web_hitbox = $Web_hitbox

func _ready():
	web_hitbox.body_entered.connect(_on_web_hitbox_body_entered)

func _on_web_hitbox_body_entered (body):
	queue_free()


func _on_timer_timeout():
	queue_free()
