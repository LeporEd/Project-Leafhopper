extends Node

# From Player
signal on_player_took_hit(new_health: int)
signal on_player_died()
signal on_player_attack()
signal on_player_grow()
signal on_player_shrink()
signal on_timer_start()
signal on_timer_stop()

# Send To Player
signal player_reset()
signal player_take_hit()
signal player_heal()
signal player_kill()
signal player_grow()
signal player_shrink()
signal player_save()
signal player_load()
signal player_teleport(position: Vector2)
signal player_deactivate_movement()
signal player_activate_movement()
signal player_start_endgame_animation()
signal timer_substract(seconds: int)
signal stop_timer()
