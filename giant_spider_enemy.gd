extends CharacterBody2D

@onready var giant_spider_animations = $Giant_spider_animations
@onready var hurtbox_2_shape = $Giant_spider_hurtbox_2/Hurtbox_2_shape

var speed = 35
var starty = position.y

func _ready():
	hurtbox_2_shape.set_deferred("disabled", true)

func _physics_process(delta):
	if position.y > starty + 500:
		hurtbox_2_shape.set_deferred("disabled", false)
		$Giant_spider_animations.animation = "Eat"
		await get_tree().create_timer(3).timeout
		hurtbox_2_shape.set_deferred("disabled", true)
		$Giant_spider_animations.animation = "Standstill"
		speed = -25
	if position.y <= starty + 300:
		await get_tree().create_timer(3).timeout
		speed = 35
	velocity.y = speed
	move_and_slide()
