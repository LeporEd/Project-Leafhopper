extends CharacterBody2D

@onready var beetle_charge_animation: AnimatedSprite2D = $Beetle_charge
@onready var beetle_hitbox: Area2D = $Beetle_hitbox

const DeathParticles = preload("res://death_explosion.tscn")

var speed = -200
var health = 2

func _ready():
	beetle_hitbox.body_entered.connect(_on_beetle_hitbox_body_entered)
	pass

func _physics_process(delta):
	if is_on_wall ():
		speed *= -1
		await get_tree().create_timer(2).timeout
		if speed < 0:
			$Beetle_charge.animation = "ChargeLeft"
		else:
			$Beetle_charge.animation = "ChargeRight"
	velocity.x = speed
	move_and_slide()
	
func _on_beetle_hitbox_body_entered (body):
	health = health - 1
	if health > 0:
		var temp = speed
		if speed < 0:
			$Beetle_charge.animation = "DamageLeft"
		else:
			$Beetle_charge.animation = "DamageRight"
		speed = speed * -2
		await get_tree().create_timer(1).timeout
		speed = 0
		await get_tree().create_timer(0.5).timeout
		speed = temp
		if speed < 0:
			$Beetle_charge.animation = "ChargeLeft"
		else:
			$Beetle_charge.animation = "ChargeRight"
	else:
		_die()

func _die():
	var particles = DeathParticles.instantiate()
	particles.position = position
	particles.restart()
	get_tree().current_scene.add_child(particles)
	queue_free()
