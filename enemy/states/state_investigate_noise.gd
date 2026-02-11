extends EnemyState

@export var search_time := 10.0
@export var _searching_speed := 8.0
@export var _search_radius := 10.0

var _search_timer := 0.0
var _player_last_seen_position: Vector3
#fast travel
var current_shortest_distance_to_entrance_vent: float = 5000.0
var current_shortest_distance_to_exit_vent: float = 5000.0
var current_entrance_vent_location: Vector3
var current_exit_vent_location: Vector3
var exit_vent_coming_out_pos: Vector3

var _nav_map: RID

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_nav_map = enemy.get_world_3d().get_navigation_map()

func enter(previous_state_name: String, data := {}) -> void:
	current_shortest_distance_to_entrance_vent = 5000.0
	current_shortest_distance_to_exit_vent = 5000.0
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	if data["player_last_seen_position"]:
		_player_last_seen_position = data["player_last_seen_position"]
	else:
		printerr("State 'Searching' was not given the player's last seen position through the data dictionary.")
		
	_search_timer = search_time

	var random_position := _player_last_seen_position + _get_random_position_inside_circle(_search_radius, _player_last_seen_position.y)
	if _should_fast_travel(enemy.global_position, random_position):
		requested_transition_to_other_state.emit("StateFastTravel",
		{"entrance_vent_location" : current_entrance_vent_location,
		"exit_vent_location" : current_exit_vent_location,
		"player_last_seen_position" : random_position,
		"exit_vent_out_position" : exit_vent_coming_out_pos,
		"state_name" : 1,})
	else:
		_go_to_position_around_player_last_seen_position(random_position)


func update(delta: float) -> void:
	_search_timer -= delta
	if _search_timer <= 0.0:
		if enemy.time <= 900.0:
			requested_transition_to_other_state.emit("StateFind")
		else:
			requested_transition_to_other_state.emit("StateRoam", {"do_not_reset_path": true})


func physics_update(_delta: float) -> void:
	var distance_to_player = enemy.global_position - enemy.player.global_position
	if distance_to_player.length() < 10.0:
		enemy.player.add_trauma(.03)

	if enemy.nav_agent.is_navigation_finished():
		var random_position := _player_last_seen_position + _get_random_position_inside_circle(_search_radius, _player_last_seen_position.y)
		_go_to_position_around_player_last_seen_position(random_position)
	
	if not enemy.is_line_of_sight_broken():
		requested_transition_to_other_state.emit("StateChase")


func _go_to_position_around_player_last_seen_position(random_position) -> void:
	enemy.travel_to_position(random_position, _searching_speed, enemy.AnimationType.RUN)


func _get_random_position_inside_circle(radius: float, height: float) -> Vector3:
	var theta: float = randf() * 2 * PI
	return Vector3(cos(theta), height, sin(theta)) * sqrt(randf()) * radius

func get_path_length(nav_map: RID, from: Vector3, to: Vector3) -> float:
	# Query the path
	var path := NavigationServer3D.map_get_path(nav_map, from, to, true)

	if not path:
		return INF

	# Sum segment lengths
	var length := 0.0
	for i in range(path.size() - 1):
		length += path[i].distance_to(path[i + 1])

	return length

func get_best_fast_travel(nav_map: RID, from: Vector3, to: Vector3) -> float:
	var d1: float
	var d2: float
	var first_vent: Node3D
	current_shortest_distance_to_entrance_vent = INF
	current_shortest_distance_to_exit_vent = INF
	current_entrance_vent_location = Vector3.ZERO
	current_exit_vent_location = Vector3.ZERO
	exit_vent_coming_out_pos = Vector3.ZERO
	for vent in enemy.vents:
		var entrance_child: Node3D = vent.get_child(0) as Node3D
		d1 = get_path_length(nav_map, from, entrance_child.global_position)

		if d1 == INF:
			continue
		
		if d1 < current_shortest_distance_to_entrance_vent:
			current_shortest_distance_to_entrance_vent = d1
			current_entrance_vent_location = vent.global_position
			first_vent = vent
	
	for vent in enemy.vents:
		if vent and vent != first_vent:
			var exit_child: Node3D = vent.get_child(0) as Node3D
			d2 = get_path_length(nav_map, exit_child.global_position, to)
			
			if d2 == INF:
				continue
			
			if d2 < current_shortest_distance_to_exit_vent:
				current_shortest_distance_to_exit_vent = d2
				current_exit_vent_location = vent.global_position
				exit_vent_coming_out_pos = exit_child.global_position
	
	return current_shortest_distance_to_entrance_vent + current_shortest_distance_to_exit_vent

func _should_fast_travel(from: Vector3, to: Vector3) -> bool:
	return get_path_length(_nav_map, from, to) > get_best_fast_travel(_nav_map, from, to)
