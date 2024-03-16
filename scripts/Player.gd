extends CharacterBody2D


const MAX_HEALTH = 100
const DEFAULT_RECEIVING_DAMAGE = 25


const MOVEMENT_SMALL = { SPEED = 100.0, JUMP_VELOCITY = -225.0, ALLOWED_JUMPS = 3 }
const MOVEMENT_NORMAL = { SPEED = 175.0, JUMP_VELOCITY = -275.0, ALLOWED_JUMPS = 2 }
const MOVEMENT_BIG = { SPEED = 125.0, JUMP_VELOCITY = -200.0, ALLOWED_JUMPS = 1 }


@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_cooldown_timer: Timer = $AnimationCooldownTimer
@onready var game_over_timer: Timer = $GameOverTimer
@onready var growth_timer: Timer = $GrowthTimer
@onready var hurtbox = $Hurtbox
@onready var item_pickup = $ItemPickup
@onready var weapon_shape = $WeaponShape

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
	is_dead = false,
	movement_profile = MOVEMENT_NORMAL
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
		_take_hit(DEFAULT_RECEIVING_DAMAGE)
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
	state.movement_profile = _get_movement_profile()


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


func _get_movement_profile():
	match state.growth:
		Growth.SMALL:
			return MOVEMENT_SMALL
		Growth.BIG:
			return MOVEMENT_BIG
		_:
			return MOVEMENT_NORMAL


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
		weapon_shape.position.x *= -1


func _update_velocity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if state.should_jump and state.jump_count < state.movement_profile.ALLOWED_JUMPS:
		velocity.y = state.movement_profile.JUMP_VELOCITY
		state.jump_count += 1
	
	if state.move_x != MoveX.NONE:
		velocity.x = state.move_x * state.movement_profile.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, state.movement_profile.SPEED)


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

