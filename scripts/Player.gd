extends CharacterBody2D

const CONFIG = {
	MAX_HEALTH = 100,
	DEFAULT_RECEIVING_DAMAGE = 25,
	SPEED = 175.0,
	JUMP_VELOCITY = -300.0,
	ALLOWED_JUMPS = 2
}

@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_cooldown_timer: Timer = $AnimationCooldownTimer
@onready var game_over_timer: Timer = $GameOverTimer
@onready var growth_timer: Timer = $GrowthTimer
@onready var hurtbox = $Hurtbox
@onready var item_pickup = $ItemPickup
@onready var weapon_shape = $Weapon2D/WeaponShape

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum MoveX {LEFT = -1, NONE = 0, RIGHT = 1}
enum MoveY {FALL = -1, NONE = 0, JUMP = 1}

enum Growth {SMALL, NORMAL, BIG}

enum GrowthTransition {
	NONE = 0,
	small_to_normal = 1,
	normal_to_big = 2,
	big_to_normal = 3,
	normal_to_small = 4	
}

enum PlayerAttack {
	NONE = 0,
	attack1 = 1,
	attack2 = 2,
	attack3 = 3,
	attack4 = 4
}

# number = priority
# 0 most important
enum PlayerAnimation {
	death = 0,
	take_hit = 1,
	small_to_normal = 2,
	normal_to_big = 3,
	big_to_normal = 4,
	normal_to_small = 5,
	attack1 = 6,
	attack2 = 7,
	attack3 = 8,
	attack4 = 9,
	fall = 10,
	jump = 11,
	run = 12,
	idle = 13
}

var async_changes = {
	should_reset = false,
	should_take_hit = false,
	should_heal = false,
	should_die = false,
	should_grow = false,
	should_shrink = false,
	should_pickup_item = false
}

var state = {
	move_x = MoveX.NONE,
	move_y = MoveY.NONE,
	should_jump = false,
	should_attack = PlayerAttack,
	should_start_animation_cooldown_timer = 0.0,
	growth = Growth.NORMAL,
	jump_count = 0,
	health = 100,
	next_animation = PlayerAnimation.idle,
	is_dead = false
}


func _ready():
	weapon_shape.disabled = true
	
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	item_pickup.body_entered.connect(_on_item_pickup_body_entered)
	
	PlayerEvents.player_reset.connect(func(): async_changes.should_reset = true)
	PlayerEvents.player_take_hit.connect(func(): async_changes.should_take_hit = true)
	PlayerEvents.player_heal.connect(func(): async_changes.should_heal = true)
	PlayerEvents.player_kill.connect(func(): async_changes.should_die = true)
	PlayerEvents.player_grow.connect(func(): async_changes.should_grow = true)
	PlayerEvents.player_shrink.connect(func(): async_changes.should_shrink = true)


func _on_hurtbox_body_entered(argument):
	print(argument)
	async_changes.should_take_hit = true


func _on_item_pickup_body_entered():
	async_changes.should_pickup_item = true


func _physics_process(delta):	
	_run_cicle(delta)
	move_and_slide()


func _run_cicle(delta):
	if state.is_dead:
		if game_over_timer.time_left > 0:
			return
		else:
			print("RESTART")
			#todo
	
	_reset_next_animation()
	_execute_async_changes()
	_update_state_with_user_input()
	_update_next_animation()
	_perform_attack()
	_perform_side_change()
	_update_velocity(delta)
	_play_animation()
	_clean_state()


func _reset_next_animation():
	state.next_animation = PlayerAnimation.idle


func _execute_async_changes():
	if async_changes.should_take_hit:
		_take_hit(CONFIG.DEFAULT_RECEIVING_DAMAGE)
		async_changes.should_take_hit = false
	if async_changes.should_pickup_item:
		pass


func _take_hit(damage: int):
	print("User was hit")
	state.health -= damage
	PlayerEvents.on_player_took_hit.emit(state.health)
	
	if state.health <= 0:
		_on_user_death()
	else:
		_suggest_next_animation(PlayerAnimation.take_hit)
		state.should_start_animation_cooldown_timer = 0.4
	

func _on_user_death():
	_suggest_next_animation(PlayerAnimation.death)
	state.is_dead = true
	PlayerEvents.on_player_died.emit()
	game_over_timer.start()
	print("Player died")


func _update_state_with_user_input():
	var user_input = _get_user_input()
	state.move_x = _convert_to_move_x(user_input.x)
	state.move_y = _convert_to_move_y()
	state.should_jump = user_input.jump
	state.jump_count = 0 if is_on_floor() else state.jump_count
	state.should_attack = _convert_to_attack(user_input)
	state.growth = _get_new_growth_and_suggest_animation(user_input.grow, user_input.shrink)


func _get_user_input():
	return {
		x = Input.get_axis("move_left", "move_right"),
		jump = Input.is_action_just_pressed("jump"),
		grow = Input.is_action_just_pressed("grow"),
		shrink = Input.is_action_just_pressed("shrink"),
		attack1 = Input.is_action_just_pressed("attack1"),
		attack2 = Input.is_action_just_pressed("attack2"),
		attack3 = Input.is_action_just_pressed("attack3"),
		attack4 = Input.is_action_just_pressed("attack4")
	}


func _convert_to_move_x(input_axis: int) -> MoveX:
	match input_axis:
		-1: 
			return MoveX.LEFT
		1: 
			return MoveX.RIGHT
		_:
			return MoveX.NONE


func _convert_to_move_y() -> MoveY:
	var vel_dir = sign(velocity.y)
	
	if vel_dir == -1:
		return MoveY.JUMP
	elif vel_dir == 1:
		return MoveY.FALL
	else:
		return MoveY.NONE


func _convert_to_attack(user_input) -> PlayerAttack:
	if user_input.attack1:
		return PlayerAttack.attack1
	if user_input.attack2:
		return PlayerAttack.attack2
	if user_input.attack3:
		return PlayerAttack.attack3
	if user_input.attack4:
		return PlayerAttack.attack4
	return PlayerAttack.NONE


func _get_new_growth_and_suggest_animation(grow: bool, shrink: bool) -> Growth:
	#todo refactor
	if animation_cooldown_timer.time_left > 0:
		return state.growth
	
	var curr_growth = state.growth
	var next_growth = curr_growth
	var growth_transition = GrowthTransition.NONE
	
	if grow:
		match curr_growth:
			Growth.SMALL:
				next_growth = Growth.NORMAL
				growth_transition = GrowthTransition.small_to_normal
				PlayerEvents.on_player_grow.emit()
			Growth.NORMAL:
				next_growth = Growth.BIG
				growth_transition = GrowthTransition.normal_to_big
				PlayerEvents.on_player_grow.emit()
			_:
				return state.growth
	elif shrink:
		match curr_growth:
			Growth.BIG:
				next_growth = Growth.NORMAL
				growth_transition = GrowthTransition.big_to_normal
				PlayerEvents.on_player_shrink.emit()
			Growth.NORMAL:
				next_growth = Growth.SMALL
				growth_transition = GrowthTransition.normal_to_small
				PlayerEvents.on_player_shrink.emit()
			_:
				return state.growth
	else:
		return state.growth
	
	var growth_animation = PlayerAnimation[GrowthTransition.keys()[growth_transition]]
	_suggest_next_animation(growth_animation)
	state.should_start_animation_cooldown_timer = 0.5
	return next_growth


func _update_next_animation():
	if state.move_x != MoveX.NONE:
		_suggest_next_animation(PlayerAnimation.run)
	if state.move_y == MoveY.JUMP:
		_suggest_next_animation(PlayerAnimation.jump)
	if state.move_y == MoveY.FALL:
		_suggest_next_animation(PlayerAnimation.fall)
	if state.should_attack != PlayerAttack.NONE:
		var attack = PlayerAttack.keys()[state.should_attack]
		var attack_animation = PlayerAnimation[attack]
		_suggest_next_animation(attack_animation)


func _suggest_next_animation(animation: PlayerAnimation):
	if animation < state.next_animation:
		state.next_animation = animation


func _perform_attack():
	if state.should_attack == PlayerAttack.NONE:
		return
	
	state.should_start_animation_cooldown_timer = 0.5
	PlayerEvents.on_player_attack.emit()
	
	#todo waffen hitboxen prüfen


func _perform_side_change():
	if state.move_x == MoveX.NONE:
		return
	
	var scale_direction = sign(sprite_2d.scale.x)
	
	if (scale_direction != state.move_x):
		sprite_2d.scale.x *= -1


func _update_velocity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if state.should_jump and state.jump_count < CONFIG.ALLOWED_JUMPS:
		velocity.y = CONFIG.JUMP_VELOCITY
		state.jump_count += 1
	
	if state.move_x != MoveX.NONE:
		velocity.x = state.move_x * CONFIG.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, CONFIG.SPEED)


func _play_animation():
	if animation_cooldown_timer.time_left > 0:
		return
	
	var next_animation = PlayerAnimation.keys()[state.next_animation]
	animation_player.play(next_animation)
	
	if state.should_start_animation_cooldown_timer > 0.0:
		animation_cooldown_timer.start(state.should_start_animation_cooldown_timer)


func _clean_state():
	state.should_jump = false
	state.should_attack = PlayerAttack.NONE
	state.should_start_animation_cooldown_timer = 0.0


#func _ready():
#	PlayerEvents.hit_player.connect(_take_hit)


#func _physics_process(delta):
#	if state.is_dying:
#		if game_over_timer.time_left <= 0:
#			PlayerEvents.player_died.emit()
#		return
#	
#	_update_state()
#	_face_player()
#	_set_velocity(delta)
#	
#	_handle_animation()
#	_perform_size_change()
#	_perform_attack()
#	
#	
#	if should_take_hit:
#		animation_cooldown_timer.start()
#		should_take_hit = false
#	
#	move_and_slide()
#
#
#func _update_state():
#	state.move_x = _get_move_x()
#	state.move_y = _get_move_y()
#	state.is_running = state.move_x != MoveX.NONE
#	state.attack = _get_attack()
#	state.is_dying = _get_is_dead()
#	state.is_hitted = true if should_take_hit else false
#	state.growth_animation = _get_growth_animation()
#	
#	if is_on_floor():
#		state.jump_count = 0
#	
#	if Input.is_action_just_pressed("restart"):
#		state.is_dying = true
#
#
#func _get_move_x() -> MoveX:
#	var direction_as_number: int = Input.get_axis("move_left", "move_right")
#	var direction_as_enum: MoveX
#	
#	match direction_as_number:
#		-1: 
#			direction_as_enum = MoveX.LEFT
#		1: 
#			direction_as_enum = MoveX.RIGHT
#		_:
#			direction_as_enum = MoveX.NONE
#		
#	return direction_as_enum
#
#
#func _get_move_y() -> MoveY:
#	var directionY: MoveY = MoveY.NONE
#	var vel_dir = sign(velocity.y)
#	
#	if vel_dir == -1:
#		directionY = MoveY.JUMP
#	elif vel_dir == 1:
#		directionY = MoveY.FALL
#
#	return directionY
#
#
#func _get_attack() -> int:
#	var attack = -1
#	
#	if Input.is_action_just_pressed("attack1"):
#		attack = 1
#	elif Input.is_action_just_pressed("attack2"):
#		attack = 2
#	elif Input.is_action_just_pressed("attack3"):
#		attack = 3
#	elif Input.is_action_just_pressed("attack4"):
#		attack = 4
#	
#	return attack
#
#
#func _get_is_dead() -> bool:
#	if state.health <= 0:
#		game_over_timer.start()
#		return true
#	
#	return false
#
#
#func _get_growth_animation() -> GrowthAnimation:
#	var animation_to_play: GrowthAnimation
#	
#	if Input.is_action_just_pressed("grow"):
#		match state.growth:
#			Growth.SMALL:
#				return GrowthAnimation.SMALL_TO_NORMAL
#			Growth.NORMAL:
#				return GrowthAnimation.NORMAL_TO_BIG
#	elif Input.is_action_just_pressed("shrink"):
#		match state.growth:
#			Growth.BIG:
#				return GrowthAnimation.BIG_TO_NORMAL
#			Growth.NORMAL:
#				return GrowthAnimation.NORMAL_TO_SMALL
#	
#	return GrowthAnimation.NONE
#
#
#func _face_player():
#	if state.move_x == MoveX.NONE:
#		return
#	
#	var scale_direction = sign(sprite_2d.scale.x)
#	
#	if (scale_direction != state.move_x):
#		sprite_2d.scale.x *= -1
#
#
#func _set_velocity(delta):	
#	if not is_on_floor():
#		velocity.y += gravity * delta
#		
#	var jump_btn_pressed = Input.is_action_just_pressed("jump")
#	
#	if jump_btn_pressed and state.jump_count < ALLOWED_JUMPS:
#		velocity.y = JUMP_VELOCITY
#		state.jump_count += 1
#	
#	if state.move_x != MoveX.NONE:
#		velocity.x = state.move_x * SPEED
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#
#
#func _perform_attack():
#	if state.attack <= 0:
#		return
#	
#	PlayerEvents.player_attack.emit(state.attack)
#	animation_cooldown_timer.start()
#
#
#func _handle_animation():
#	var animation: String = "idle"
#	
#	if state.is_running:
#		animation = "run"
#	if state.move_y == MoveY.FALL:
#		animation = "fall"
#	if state.move_y == MoveY.JUMP:
#		animation = "jump"
#	if state.attack == 1:
#		animation = "attack1"
#	if state.attack == 2:
#		animation = "attack2"
#	if state.attack == 3:
#		animation = "attack3"
#	if state.attack == 4:
#		animation = "attack4"
#	if state.growth_animation != GrowthAnimation.NONE:
#		animation = _get_growth_animation_as_string()
#	if state.is_hitted:
#		animation = "take_hit"
#	if state.is_dying:
#		animation = "death"
#	
#	if (not animation_cooldown_timer.time_left > 0) and (not growth_timer.time_left > 0):
#		animation_player.play(animation)
#
#
#func _get_growth_animation_as_string() -> String:
#	match state.growth_animation:
#		GrowthAnimation.SMALL_TO_NORMAL:
#			return "small_to_normal"
#		GrowthAnimation.NORMAL_TO_BIG:
#			return "normal_to_big"
#		GrowthAnimation.BIG_TO_NORMAL:
#			return "big_to_normal"
#		GrowthAnimation.NORMAL_TO_SMALL:
#			return "normal_to_small"
#		_:
#			return ""
#
#
#func _perform_size_change():
#	var new_growth = _get_new_growth()
#	
#	if new_growth != state.growth:
#		state.growth = new_growth
#		growth_timer.start()
#
#
#func _get_new_growth() -> Growth:
#	match state.growth_animation:
#		GrowthAnimation.SMALL_TO_NORMAL:
#			return Growth.NORMAL
#		GrowthAnimation.NORMAL_TO_BIG:
#			return Growth.BIG
#		GrowthAnimation.BIG_TO_NORMAL:
#			return Growth.NORMAL
#		GrowthAnimation.NORMAL_TO_SMALL:
#			return Growth.SMALL
#		_:
#			return state.growth
#
#
#func _take_hit(damage: int):
#	print("Player was hit with", damage, "damage points")
#	state.health -= damage
#	should_take_hit = true
#	PlayerEvents.player_took_hit.emit(state.health)

