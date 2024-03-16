extends CharacterBody2D

@onready var maggot_walk_animation: AnimatedSprite2D = $Maggot_walk
@onready var maggot_hitbox: Area2D = $Maggot_Hitbox

const DeathParticles = preload("res://death_explosion.tscn")

var speed = -50

func _ready():
	#maggot_hitbox.body_entered.connect(_on_Maggot_Hitbox_body_entered)
	pass

func _physics_process(delta):
	if is_on_wall ():
		speed *= -1
		$Maggot_walk.animation = "Walk" + str(speed)
	velocity.x = speed
	move_and_slide()

func _die():
	var particles = DeathParticles.instantiate()
	particles.position = position
	particles.restart()
	get_tree().current_scene.add_child(particles)
	queue_free()
	
####func _on_Maggot_Hitbox_body_entered (body)   ######## Damage against Player
