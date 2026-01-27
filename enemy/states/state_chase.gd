extends EnemyState

@export var chase_max_time := 8.0
@export var update_path_delay := 0.0 # if you do not want to update the path every physics frame, increase this
@export var _chasing_speed := 8.0
@export var _catching_distance := 1.4

var _chase_timer := 0.0
var _update_path_timer := 0.0


func enter(previous_state_name: String, data := {}) -> void:
	_chase_timer = chase_max_time
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL


func update(delta: float) -> void:
	enemy.has_heard_noise = false
	_update_path_timer -= delta
	_chase_timer -= delta
	if _chase_timer <= 0.0:
		requested_transition_to_other_state.emit("StateSearch", {"player_last_seen_position":enemy.player.global_position})


func physics_update(_delta: float) -> void:
	var distance_to_player = enemy.global_position - enemy.player.global_position
	if distance_to_player.length() < 10.0:
		enemy.player.add_trauma(.03)
	if _update_path_timer <= 0.0:
		_update_path_timer = update_path_delay
		enemy.travel_to_position(enemy.player.global_position, _chasing_speed, enemy.AnimationType.RUN)
	
	if not enemy.is_line_of_sight_broken():
		_chase_timer = chase_max_time
	
	if enemy.global_position.distance_to(enemy.player.global_position) <= _catching_distance:
		enemy.reached_player.emit()
