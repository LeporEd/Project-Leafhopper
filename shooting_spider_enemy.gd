extends CharacterBody2D

@onready var spider_animations = $Spider_Animations
@onready var spider_hitbox = $Spider_hitbox

const WebScene = preload("res://spider_web_shot.tscn")
const DeathParticles = preload("res://death_explosion.tscn")

var speed = -75

func _ready():
	spider_hitbox.body_entered.connect(_on_spider_hitbox_body_entered)

func _physics_process(delta):
	if is_on_wall ():
		speed *= -1
		_spider_set_walk()
	velocity.x = speed
	move_and_slide()

func _on_spider_hitbox_body_entered (body):
	_die()

func _spider_set_walk ():
	if speed < 0:
		$Spider_Animations.animation = "WalkLeft"
	else:
		$Spider_Animations.animation = "WalkRight"

func _die():
	var particles = DeathParticles.instantiate()
	particles.position = position
	particles.restart()
	get_tree().current_scene.add_child(particles)
	queue_free()

func _on_spider_timer_timeout():
	var temp = speed
	speed = 0
	if temp < 0:
		$Spider_Animations.animation = "ShootLeft"
	else:
		$Spider_Animations.animation = "ShootRight"
	await get_tree().create_timer(1).timeout
	var SpiderWeb = WebScene.instantiate()
	SpiderWeb.position = position
	SpiderWeb.linear_velocity = Vector2(temp * 3, 0.0)
	get_tree().current_scene.add_child(SpiderWeb)
	SpiderWeb.visible = false
	speed = temp
	_spider_set_walk()
