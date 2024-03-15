extends CharacterBody2D

@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer


const SPEED = 175.0
const JUMP_VELOCITY = -300.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


#func _physics_process(delta):
#	
#	# Add the gravity.
#	if not is_on_floor():
#		velocity.y += gravity * delta
#
#	# Handle jump.
#	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
#		velocity.y = JUMP_VELOCITY
#
#	# Get the input direction and handle the movement/deceleration.
#	# As good practice, you should replace UI actions with custom gameplay actions.
#	var direction = Input.get_axis("ui_left", "ui_right")
#	if direction:
#		velocity.x = direction * SPEED
#		animation_player.play("run")
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#		animation_player.play("Idle")
#
#	move_and_slide()

enum MoveDirection {LEFT = -1, NONE = 0, RIGHT = 1}


func _physics_process(delta):
	var move_direction: MoveDirection = _get_move_direction()
	
	var is_running = move_direction != MoveDirection.NONE
	var is_jumping = Input.is_action_just_pressed("ui_accept") and is_on_floor()
	var is_falling = false
	var is_hitted = false
	var is_dying = false
	var attack = 0
	
	
	_face_player(move_direction)
	_set_velocity(move_direction, is_jumping, delta)
	_handle_animation(is_running, is_jumping, is_falling, is_hitted, is_dying, attack)
	
	move_and_slide()
	
func _get_move_direction() -> MoveDirection:
	var direction_as_number: int = Input.get_axis("ui_left", "ui_right")
	
	var direction_as_enum: MoveDirection = MoveDirection.NONE
	
	match direction_as_number:
		-1: 
			direction_as_enum = MoveDirection.LEFT
		1: 
			direction_as_enum = MoveDirection.RIGHT
		
	return direction_as_enum
	
	
	
func _face_player(move_direction):
	if move_direction == MoveDirection.NONE:
		return
	
	var scale_direction = sign(sprite_2d.scale.x)
	
	if (scale_direction != move_direction):
		sprite_2d.scale.x *= -1
	
func _set_velocity(move_direction, is_jumping, delta):	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	if is_jumping:
		velocity.y = JUMP_VELOCITY
	
	if move_direction != MoveDirection.NONE:
		velocity.x = move_direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
func _handle_animation(is_running, is_jumping, is_falling, is_hitted, is_dying, attack):
	var animation: String = "idle"
	
	if is_running:
		animation = "run"
	if is_falling:
		animation = "fall"
	if is_jumping:
		animation = "jump"
	if attack == 1:
		animation = "attack1"
	if attack == 2:
		animation = "attack2"
	if attack == 3:
		animation = "attack3"
	if attack == 4:
		animation = "attack4"
	if is_hitted:
		animation = "take_hit"
	if is_dying:
		animation = "death"
	
	animation_player.play(animation)
	
	
