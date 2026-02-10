extends EnemyState

@export var stun_max_time := 5.0

var _stun_timer := 0.0


func enter(previous_state_name: String, data := {}) -> void:
	_stun_timer = stun_max_time
	enemy.nav_agent.target_position = enemy.global_position


func update(delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	enemy._current_speed = 0.0
	enemy.velocity = Vector3.ZERO
	enemy.nav_agent.target_position = enemy.global_position
