extends CharacterBody2D

@onready var beetle_charge_animation: AnimatedSprite2D = $Beetle_charge
@onready var beetle_hitbox: Area2D = $Beetle_hitbox

var speed = -200

func _ready():
	#beetle_hitbox.body_entered.connect(_on_Beetle_Hitbox_body_entered)
	pass

func _physics_process(delta):
	if is_on_wall ():
		speed *= -1
		await get_tree().create_timer(2).timeout
		$Beetle_charge.animation = "Charge" + str(speed)
	velocity.x = speed
	move_and_slide()
	
####func _on_Beetle_hitbox_body_entered (body)   ######## Damage against Player
