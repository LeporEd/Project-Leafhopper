extends CharacterBody2D

@onready var beetle_charge_animation: AnimatedSprite2D = $Beetle_charge
@onready var beetle_hitbox: Area2D = $Beetle_hitbox
@onready var dazed_timer = $Dazed_Timer
@onready var beetle_collision = $Beetle_hitbox/beetle_collision

const DeathParticles = preload("res://death_explosion.tscn")

var speed = -160
var health = 2
var dazed = false

func _ready():
	beetle_hitbox.body_entered.connect(_on_beetle_hitbox_body_entered)
	PlayerEvents.player_load.connect(_respawn_enemy)

func _physics_process(delta):
	if is_on_wall () && dazed == false:
		dazed = true
		dazed_timer.start(2)
	velocity.x = speed
	move_and_slide()
	
func _on_beetle_hitbox_body_entered (body):
	health = health - 1
	if health > 0:
		beetle_collision.set_deferred("disabled", true)
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
		beetle_collision.set_deferred("disabled", false)
	else:
		_die()

func _die():
	var particles = DeathParticles.instantiate()
	particles.position = position
	particles.restart()
	get_tree().current_scene.add_child(particles)
	queue_free()

func _respawn_enemy():
	health = 2


func _on_dazed_timer_timeout():
	speed *= -1
	if speed < 0:
		$Beetle_charge.animation = "ChargeLeft"
		position.x = position.x - 5
	else:
		$Beetle_charge.animation = "ChargeRight"
		position.x = position.x + 5
	dazed = false
	dazed_timer.stop()
