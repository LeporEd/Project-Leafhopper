extends CharacterBody2D

@onready var giant_spider_animations = $Giant_spider_animations
@onready var hurtbox_2_shape = $Giant_spider_hurtbox_2/Hurtbox_2_shape
@onready var giant_spider_hurtbox_1 = $Giant_spider_hurtbox_1
@onready var giant_spider_hurtbox_2 = $Giant_spider_hurtbox_2

const DeathParticles = preload("res://death_explosion.tscn")

var speed = 35
var health = 10
var starty = position.y
var hurt = false

func _ready():
	hurtbox_2_shape.set_deferred("disabled", true)
	PlayerEvents.player_load.connect(_respawn_enemy)

func _physics_process(delta):
	if position.y > starty + 150 && hurt == false:
		hurtbox_2_shape.set_deferred("disabled", false)
		$Giant_spider_animations.animation = "Eat"
		await get_tree().create_timer(3).timeout
		hurtbox_2_shape.set_deferred("disabled", true)
		$Giant_spider_animations.animation = "Standstill"
		speed = -25
	if position.y <= starty + 50:
		await get_tree().create_timer(3).timeout
		speed = 35
	if hurt == false:
		velocity.y = speed
		move_and_slide()

func _on_ouchie_area_body_entered(body):
	health = health - 1
	hurt = true
	if health > 0:
		var temp = speed
		speed = 0
		hurtbox_2_shape.set_deferred("disabled", true)
		$Giant_spider_animations.animation = "Damage"
		await get_tree().create_timer(1).timeout
		$Giant_spider_animations.animation = "Standstill"
		speed = temp
	else:
		_die()
	hurt = false

func _die():
	var particles = DeathParticles.instantiate()
	particles.position = position
	particles.restart()
	get_tree().current_scene.add_child(particles)
	
	
	queue_free()

func _respawn_enemy():
	health = 10
