extends CharacterBody2D

@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_cooldown_timer: Timer = $AnimationCooldownTimer
@onready var game_over_timer: Timer = $GameOverTimer
@onready var growth_timer: Timer = $GrowthTimer


const MAX_HEALTH = 100
const SPEED = 175.0
const JUMP_VELOCITY = -300.0
const ALLOWED_JUMPS = 2

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum MoveX {LEFT = -1, NONE = 0, RIGHT = 1}
enum MoveY {FALL = -1, NONE = 0, JUMP = 1}

enum Growth {SMALL, NORMAL, BIG}

enum GrowthAnimation {
	NONE,
	SMALL_TO_NORMAL,
	NORMAL_TO_BIG,
	BIG_TO_NORMAL,
	NORMAL_TO_SMALL	
}

# can be set any time in the cycle
# is read at the apropriate position
var should_take_hit = false


var state = {
	move_x = MoveX.NONE,
	move_y = MoveY.NONE,
	is_running = false,
	is_hitted = false,
	is_dying = false,
	attack = -1,
	jump_count = 0,
	growth = Growth.NORMAL,
	growth_animation = GrowthAnimation.NONE,
	health = MAX_HEALTH
}


func _ready():
	PlayerEvents.hit_player.connect(_take_hit)


func _physics_process(delta):
	if state.is_dying:
		if game_over_timer.time_left <= 0:
			PlayerEvents.player_died.emit()
		return
	
	_update_state()
	_face_player()
	_set_velocity(delta)
	
	_handle_animation()
	_perform_size_change()
	_perform_attack()
	
	
	if should_take_hit:
		animation_cooldown_timer.start()
		should_take_hit = false
	
	move_and_slide()


func _update_state():
	state.move_x = _get_move_x()
	state.move_y = _get_move_y()
	state.is_running = state.move_x != MoveX.NONE
	state.attack = _get_attack()
	state.is_dying = _get_is_dead()
	state.is_hitted = true if should_take_hit else false
	state.growth_animation = _get_growth_animation()
	
	if is_on_floor():
		state.jump_count = 0
	
	if Input.is_action_just_pressed("restart"):
		state.is_dying = true


func _get_move_x() -> MoveX:
	var direction_as_number: int = Input.get_axis("move_left", "move_right")
	var direction_as_enum: MoveX
	
	match direction_as_number:
		-1: 
			direction_as_enum = MoveX.LEFT
		1: 
			direction_as_enum = MoveX.RIGHT
		_:
			direction_as_enum = MoveX.NONE
		
	return direction_as_enum


func _get_move_y() -> MoveY:
	var directionY: MoveY = MoveY.NONE
	var vel_dir = sign(velocity.y)
	
	if vel_dir == -1:
		directionY = MoveY.JUMP
	elif vel_dir == 1:
		directionY = MoveY.FALL

	return directionY


func _get_attack() -> int:
	var attack = -1
	
	if Input.is_action_just_pressed("attack1"):
		attack = 1
	elif Input.is_action_just_pressed("attack2"):
		attack = 2
	elif Input.is_action_just_pressed("attack3"):
		attack = 3
	elif Input.is_action_just_pressed("attack4"):
		attack = 4
	
	return attack


func _get_is_dead() -> bool:
	if state.health <= 0:
		game_over_timer.start()
		return true
	
	return false


func _get_growth_animation() -> GrowthAnimation:
	var animation_to_play: GrowthAnimation
	
	if Input.is_action_just_pressed("grow"):
		match state.growth:
			Growth.SMALL:
				return GrowthAnimation.SMALL_TO_NORMAL
			Growth.NORMAL:
				return GrowthAnimation.NORMAL_TO_BIG
	elif Input.is_action_just_pressed("shrink"):
		match state.growth:
			Growth.BIG:
				return GrowthAnimation.BIG_TO_NORMAL
			Growth.NORMAL:
				return GrowthAnimation.NORMAL_TO_SMALL
	
	return GrowthAnimation.NONE


func _face_player():
	if state.move_x == MoveX.NONE:
		return
	
	var scale_direction = sign(sprite_2d.scale.x)
	
	if (scale_direction != state.move_x):
		sprite_2d.scale.x *= -1


func _set_velocity(delta):	
	if not is_on_floor():
		velocity.y += gravity * delta
		
	var jump_btn_pressed = Input.is_action_just_pressed("jump")
	
	if jump_btn_pressed and state.jump_count < ALLOWED_JUMPS:
		velocity.y = JUMP_VELOCITY
		state.jump_count += 1
	
	if state.move_x != MoveX.NONE:
		velocity.x = state.move_x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func _perform_attack():
	if state.attack <= 0:
		return
	
	PlayerEvents.player_attack.emit(state.attack)
	animation_cooldown_timer.start()


func _handle_animation():
	var animation: String = "idle"
	
	if state.is_running:
		animation = "run"
	if state.move_y == MoveY.FALL:
		animation = "fall"
	if state.move_y == MoveY.JUMP:
		animation = "jump"
	if state.attack == 1:
		animation = "attack1"
	if state.attack == 2:
		animation = "attack2"
	if state.attack == 3:
		animation = "attack3"
	if state.attack == 4:
		animation = "attack4"
	if state.growth_animation != GrowthAnimation.NONE:
		animation = _get_growth_animation_as_string()
	if state.is_hitted:
		animation = "take_hit"
	if state.is_dying:
		animation = "death"
	
	if (not animation_cooldown_timer.time_left > 0) and (not growth_timer.time_left > 0):
		animation_player.play(animation)


func _get_growth_animation_as_string() -> String:
	match state.growth_animation:
		GrowthAnimation.SMALL_TO_NORMAL:
			return "small_to_normal"
		GrowthAnimation.NORMAL_TO_BIG:
			return "normal_to_big"
		GrowthAnimation.BIG_TO_NORMAL:
			return "big_to_normal"
		GrowthAnimation.NORMAL_TO_SMALL:
			return "normal_to_small"
		_:
			return ""


func _perform_size_change():
	var new_growth = _get_new_growth()
	
	if new_growth != state.growth:
		state.growth = new_growth
		growth_timer.start()


func _get_new_growth() -> Growth:
	match state.growth_animation:
		GrowthAnimation.SMALL_TO_NORMAL:
			return Growth.NORMAL
		GrowthAnimation.NORMAL_TO_BIG:
			return Growth.BIG
		GrowthAnimation.BIG_TO_NORMAL:
			return Growth.NORMAL
		GrowthAnimation.NORMAL_TO_SMALL:
			return Growth.SMALL
		_:
			return state.growth


func _take_hit(damage: int):
	print("Player was hit with", damage, "damage points")
	state.health -= damage
	should_take_hit = true
	PlayerEvents.player_took_hit.emit(state.health)

