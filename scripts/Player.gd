extends CharacterBody2D

const INITIAL_POSITION = {
	X = 5750,
	Y = 250
}

const BOUNDARY_BOTTOM_Y = 600

const MAX_HEALTH = 3
const DEFAULT_RECEIVING_DAMAGE = 1

const MOVEMENT_SMALL = { SPEED = 100.0, JUMP_VELOCITY = -225.0, ALLOWED_JUMPS = 3 }
const MOVEMENT_NORMAL = { SPEED = 175.0, JUMP_VELOCITY = -275.0, ALLOWED_JUMPS = 2 }
const MOVEMENT_BIG = { SPEED = 130.0, JUMP_VELOCITY = -260.0, ALLOWED_JUMPS = 1 }


@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var animation_cooldown_timer: Timer = $AnimationCooldownTimer
@onready var game_over_timer: Timer = $GameOverTimer
@onready var hurtbox = $Hurtbox
@onready var weapon = $Weapon
@onready var weapon_shape = $Weapon/WeaponShape
@onready var audio_running = $AudioRunning
@onready var audio_death = $AudioDeath
@onready var audio_jump = $AudioJump
@onready var audio_land = $AudioLand
@onready var audio_hit = $AudioHit
@onready var audio_sword = $AudioSword
@onready var pause_menu = $Camera2D/Pause_menu

@onready var growth_texture_rect = $PlayerUI/GrowthTextureRect
@onready var weapon_texture_rect = $PlayerUI/WeaponTextureRect
@onready var health_bar = $PlayerUI/HealthBar
@onready var death_texture_rect = $PlayerUI/DeathTextureRect

var arrow_up_icon = preload("res://assets/UI/arrow_up.png")
var arrow_down_icon = preload("res://assets/UI/arrow_down.png")
var box_icon = preload("res://assets/UI/box.png")

var weapon1_icon = preload("res://assets/UI/weapon1.png")
var weapon2_icon = preload("res://assets/UI/weapon2.png")
var weapon3_icon = preload("res://assets/UI/weapon3.png")
var weapon4_icon = preload("res://assets/UI/weapon4.png")

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
	attack1,
	attack2,
	attack3,
	attack4
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
	should_save = false,
	should_load = false,
	should_teleport = null
}

var paused = false

class State:
	var move_x = MoveX.NONE
	var move_y = MoveY.NONE
	var in_air = false
	var selected_weapon = PlayerAttack.attack1
	var should_jump = false
	var should_go_down = false
	var should_attack = false
	var should_start_animation_cooldown_timer = 0.0
	var growth = Growth.NORMAL
	var jump_count = 0
	var health: int = MAX_HEALTH
	var next_animation = PlayerAnimation.idle
	var is_dead = false
	var movement_profile = MOVEMENT_NORMAL
	var sound_running = false
	var sound_death = false
	var sound_jump = false
	var sound_land = false
	var sound_hit = false
	var sound_sword = false
	
	static func from(prev_state: State) -> State:
		var clone = State.new()
		clone.move_x = prev_state.move_x
		clone.move_y = prev_state.move_y
		clone.selected_weapon = prev_state.selected_weapon
		clone.growth = prev_state.growth
		clone.jump_count = prev_state.jump_count
		clone.health = prev_state.health
		clone.is_dead = prev_state.is_dead
		clone.movement_profile = prev_state.movement_profile

		return clone


var state: State = State.new()


class Checkpoint:
	var x: float
	var y: float
	var state: State
	
	func _init(x: float, y: float, state: State):
		self.x = x
		self.y = y
		self.state = state


var checkpoints = []


func _ready():
	_reset()
	
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	
	PlayerEvents.player_reset.connect(func(): async_changes.should_reset = true)
	PlayerEvents.player_take_hit.connect(func(): async_changes.should_take_hit = true)
	PlayerEvents.player_heal.connect(func(): async_changes.should_heal = true)
	PlayerEvents.player_kill.connect(func(): async_changes.should_die = true)
	PlayerEvents.player_grow.connect(func(): async_changes.should_grow = true)
	PlayerEvents.player_shrink.connect(func(): async_changes.should_shrink = true)
	PlayerEvents.player_save.connect(func(): async_changes.should_save = true)
	PlayerEvents.player_load.connect(func(): async_changes.should_load = true)
	PlayerEvents.player_teleport.connect(func(position): async_changes.should_teleport = position)


func _reset():
	state = State.new()
	position.x = INITIAL_POSITION.X
	position.y = INITIAL_POSITION.Y
	
	weapon_shape.disabled = true
	health_bar.value = state.health
	growth_texture_rect.texture = box_icon
	weapon_texture_rect.texture = weapon1_icon
	death_texture_rect.visible = false
	


func _on_hurtbox_body_entered(argument):
	print(argument)
	async_changes.should_take_hit = true


func _physics_process(delta):	
	_run_cicle(delta)
	move_and_slide()


func _run_cicle(delta):
	if state.is_dead:
		if game_over_timer.time_left > 0:
			_clean_state()
			_update_velocity(delta)
			return
	
	_reset_next_animation()
	_execute_async_changes()
	_check_player_boundaries()
	_update_state_with_user_input()
	_update_next_animation_and_sound()
	_update_ui()
	_perform_go_down()
	_perform_attack()
	_perform_side_change()
	_update_velocity(delta)
	_play_animation()
	_play_audio()
	_clean_state()


func _reset_next_animation():
	state.next_animation = PlayerAnimation.idle


func _execute_async_changes():
	if async_changes.should_heal:
		state.health = MAX_HEALTH
		async_changes.should_heal = false
	if async_changes.should_die:
		state.health = 0
		async_changes.should_die = false
		_on_user_death()
	if async_changes.should_reset:
		_reset()
		async_changes.should_reset = false
	if async_changes.should_grow || async_changes.should_shrink:
		state.growth = _get_new_growth_and_suggest_animation(async_changes.should_grow, async_changes.should_shrink)
		async_changes.should_grow = false
		async_changes.should_shrink = false
	if async_changes.should_save:
		_save_checkpoint()
		async_changes.should_save = false
	if async_changes.should_load:
		_load_last_checkpoint()
		async_changes.should_load = false
	if async_changes.should_take_hit:
		_take_hit(DEFAULT_RECEIVING_DAMAGE)
		async_changes.should_take_hit = false
	if async_changes.should_teleport != null:
		print("Teleport:", async_changes.should_teleport)
		position.x = async_changes.should_teleport.x
		position.y = async_changes.should_teleport.y
		async_changes.should_teleport = null


func _save_checkpoint():
	var checkpoint = Checkpoint.new(position.x, position.y, State.from(state))
	checkpoints.append(checkpoint)
	print("Checkpoint created:", checkpoint)


func _load_last_checkpoint():
	print("Player reset")
	_reset()
	
	if checkpoints.size() > 0:
		var checkpoint = checkpoints[checkpoints.size() - 1]
		print("Load checkpoint:", checkpoint)
		
		position.x = checkpoint.x
		position.y = checkpoint.y
		state = checkpoint.state
		health_bar.value = state.health
		print("Health", state.health)


func _take_hit(damage: int):
	print("User was hit")
	state.health -= damage
	PlayerEvents.on_player_took_hit.emit(state.health)
	health_bar.value = state.health
	
	if state.health <= 0:
		_on_user_death()
	else:
		_suggest_next_animation(PlayerAnimation.take_hit)
		state.sound_hit = true
		state.should_start_animation_cooldown_timer = 0.4
	

func _on_user_death():
	_suggest_next_animation(PlayerAnimation.death)
	state.sound_death = true
	state.is_dead = true
	death_texture_rect.visible = true
	PlayerEvents.on_player_died.emit()
	game_over_timer.start()
	print("Player died")


func _check_player_boundaries():
	if position.y > BOUNDARY_BOTTOM_Y:
		state.health = 0
		health_bar.value = state.health
		_on_user_death()


func _update_state_with_user_input():
	if paused == false:
		var user_input = _get_user_input()
		state.move_x = _convert_to_move_x(user_input.x)
		state.move_y = _convert_to_move_y()
		state.should_jump = user_input.jump
		state.should_go_down = user_input.go_down
		state.jump_count = 0 if is_on_floor() else state.jump_count
		state.should_attack = user_input.attack
		state.growth = _get_new_growth_and_suggest_animation(user_input.grow, user_input.shrink)
		state.movement_profile = _get_movement_profile()
		state.sound_land = is_on_floor() && state.in_air
		state.in_air = not is_on_floor()
		
		_update_selected_weapon(user_input)


func _get_user_input():
	return {
		x = Input.get_axis("move_left", "move_right"),
		jump = Input.is_action_just_pressed("jump"),
		go_down = Input.is_action_just_pressed("go_down"),
		grow = Input.is_action_just_pressed("grow"),
		shrink = Input.is_action_just_pressed("shrink"),
		attack = Input.is_action_just_pressed("attack"),
		weapon1 = Input.is_action_just_pressed("weapon1"),
		weapon2 = Input.is_action_just_pressed("weapon2"),
		weapon3 = Input.is_action_just_pressed("weapon3"),
		weapon4 = Input.is_action_just_pressed("weapon4")
	}

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		_pause_menu()

func _pause_menu():
	if paused:
		pause_menu.hide()
		Engine.time_scale = 1
	else:
		pause_menu.show()
		Engine.time_scale = 0
	paused = !paused

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


func _update_selected_weapon(user_input):
	if user_input.weapon1:
		state.selected_weapon = PlayerAttack.attack1
	if user_input.weapon2:
		state.selected_weapon = PlayerAttack.attack2
	if user_input.weapon3:
		state.selected_weapon = PlayerAttack.attack3
	if user_input.weapon4:
		state.selected_weapon = PlayerAttack.attack4


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


func _update_next_animation_and_sound():
	if state.move_x != MoveX.NONE:
		_suggest_next_animation(PlayerAnimation.run)
	if state.move_y == MoveY.JUMP:
		_suggest_next_animation(PlayerAnimation.jump)
		state.sound_jump = true
	if state.move_y == MoveY.FALL:
		_suggest_next_animation(PlayerAnimation.fall)
	if state.should_attack:
		var attack = PlayerAttack.keys()[state.selected_weapon]
		var attack_animation = PlayerAnimation[attack]
		_suggest_next_animation(attack_animation)
		state.sound_sword = true


func _suggest_next_animation(animation: PlayerAnimation):
	if animation < state.next_animation:
		state.next_animation = animation


func _update_ui():
	match state.growth:
		Growth.SMALL:
			growth_texture_rect.texture = arrow_down_icon
		Growth.NORMAL:
			growth_texture_rect.texture = box_icon
		Growth.BIG:
			growth_texture_rect.texture = arrow_up_icon
	
	match state.selected_weapon:
		PlayerAttack.attack1:
			weapon_texture_rect.texture = weapon1_icon
		PlayerAttack.attack2:
			weapon_texture_rect.texture = weapon2_icon
		PlayerAttack.attack3:
			weapon_texture_rect.texture = weapon3_icon
		PlayerAttack.attack4:
			weapon_texture_rect.texture = weapon4_icon


func _perform_go_down():
	if state.should_go_down:
		position.y += 1


func _perform_attack():
	if not state.should_attack:
		return
	
	state.should_start_animation_cooldown_timer = 0.5
	PlayerEvents.on_player_attack.emit()


func _perform_side_change():
	if state.move_x == MoveX.NONE:
		return
	
	var scale_direction = sign(sprite_2d.scale.x)
	
	if (scale_direction != state.move_x):
		sprite_2d.scale.x *= -1
		weapon.scale.x *= -1


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


func _play_audio():
	if state.move_x == MoveX.NONE || not is_on_floor():
		audio_running.stop()
	elif not audio_running.playing:
		audio_running.play()
	
	if not audio_death.playing and state.sound_death:
		audio_death.play(0.0)
	if state.sound_hit:
		audio_hit.play(0.0)
	if state.sound_jump:
		audio_jump.play(0.04)
	if state.sound_land:
		audio_land.play(0.0)
	if state.sound_sword:
		audio_sword.play(0.0)


func _clean_state():
	state.move_x = MoveX.NONE
	state.move_y = MoveY.NONE
	state.should_jump = false
	state.should_attack = false
	state.should_start_animation_cooldown_timer = 0.0
	state.sound_running = false
	state.sound_death = false
	state.sound_jump = false
	state.should_go_down = false
	state.sound_land = false
	state.sound_hit = false
	state.sound_sword = false

