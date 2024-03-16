extends Node

# Emitted from Player
signal player_attack(weapon: int)
signal player_took_hit(new_health: int)
signal player_died()

# Emitted from external
signal hit_player(damage: int)

