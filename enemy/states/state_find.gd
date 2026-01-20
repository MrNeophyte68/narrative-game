extends EnemyState

@export var _find_speed := 2.8
@export var _search_radius := 10.0
@export var _hear_radius := 20.0

var _player_last_seen_position: Vector3


func enter(previous_state_name: String, data := {}) -> void:
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	_go_to_position_around_player()


func update(delta: float) -> void:
	if enemy.player.sanity_controller.sanity > 51.0:
		requested_transition_to_other_state.emit("StateRoam", {"do_not_reset_path": true})


func physics_update(_delta: float) -> void:
	if enemy.nav_agent.is_navigation_finished():
		_go_to_position_around_player()
	
	if not enemy.is_line_of_sight_broken():
		requested_transition_to_other_state.emit("StateChase")
	
	if enemy.has_heard_noise:
		var distance_to_object = enemy.global_position - enemy.object_heard_location
		if distance_to_object.length() < _hear_radius:
			requested_transition_to_other_state.emit("StateInvestigateNoise", {"player_last_seen_position": enemy.object_heard_location})
		enemy.has_heard_noise = false


func _go_to_position_around_player() -> void:
	_player_last_seen_position = enemy.player.global_position
	_search_radius = 30.0 * (enemy.player.sanity_controller.sanity / 100.0)
	var random_position := _player_last_seen_position + _get_random_position_inside_circle(_search_radius, _player_last_seen_position.y)
	enemy.travel_to_position(random_position, _find_speed, true)


func _get_random_position_inside_circle(radius: float, height: float) -> Vector3:
	var theta: float = randf() * 2 * PI
	return Vector3(cos(theta), height, sin(theta)) * sqrt(randf()) * radius
