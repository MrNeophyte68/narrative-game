extends EnemyState

@export var stun_max_time := 5.0

var _stun_timer := 0.0


func enter(previous_state_name: String, data := {}) -> void:
	_stun_timer = stun_max_time
	enemy.nav_agent.target_position = enemy.global_position


func update(delta: float) -> void:
	_stun_timer -= delta
	if _stun_timer <= 0.0:
		requested_transition_to_other_state.emit("StateSearch", {"player_last_seen_position":enemy.player.global_position})


func physics_update(_delta: float) -> void:
	enemy.nav_agent.target_position = enemy.global_position
