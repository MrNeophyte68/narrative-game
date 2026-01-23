extends EnemyState

@export var search_time := 10.0
@export var _searching_speed := 8.0
@export var _search_radius := 10.0

var _search_timer := 0.0
var _player_last_seen_position: Vector3


func enter(previous_state_name: String, data := {}) -> void:
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	if data["player_last_seen_position"]:
		_player_last_seen_position = data["player_last_seen_position"]
	else:
		printerr("State 'Searching' was not given the player's last seen position through the data dictionary.")
		
	_search_timer = search_time
	_go_to_position_around_player_last_seen_position()


func update(delta: float) -> void:
	enemy.has_heard_noise = false
	_search_timer -= delta
	if _search_timer <= 0.0:
		if enemy.player.sanity_controller.sanity > 51.0:
			requested_transition_to_other_state.emit("StateRoam", {"do_not_reset_path": true})
		else:
			requested_transition_to_other_state.emit("StateFind")


func physics_update(_delta: float) -> void:
	if enemy.nav_agent.is_navigation_finished():
		_go_to_position_around_player_last_seen_position()
	
	var distance_to_player = enemy.global_position - enemy.player.global_position
	if distance_to_player.length() < 10.0:
		enemy.player.add_trauma(.03)
	
	if not enemy.is_line_of_sight_broken():
		requested_transition_to_other_state.emit("StateChase")


func _go_to_position_around_player_last_seen_position() -> void:
	var random_position := _player_last_seen_position + _get_random_position_inside_circle(_search_radius, _player_last_seen_position.y)
	enemy.travel_to_position(random_position, _searching_speed, enemy.AnimationType.RUN)


func _get_random_position_inside_circle(radius: float, height: float) -> Vector3:
	var theta: float = randf() * 2 * PI
	return Vector3(cos(theta), height, sin(theta)) * sqrt(randf()) * radius
