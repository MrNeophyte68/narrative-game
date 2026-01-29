extends EnemyState

@export var _roaming_speed := 3.0
@export var _hear_radius := 30.0
@export var _patience_time := 10.0

var _map_synchronized := false
var _target_position: Vector3
var _nav_map: RID
var _patience_timer := 0.0
#fast travel
const FAST_TRAVEL_DURATION = 30.0 #threshold before it may fast travel
var time_before_fast_travel : float = FAST_TRAVEL_DURATION
var current_shortest_distance_to_entrance_vent: float = 5000.0
var current_shortest_distance_to_exit_vent: float = 5000.0
var current_entrance_vent_location: Vector3
var current_exit_vent_location: Vector3
var exit_vent_coming_out_pos: Vector3
var random_position: Vector3


func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_map_synchronized = true
	_nav_map = enemy.get_world_3d().get_navigation_map()
	_patience_timer = _patience_time


func enter(previous_state_name: String, data := {}) -> void:
	if not _map_synchronized:
		return
	current_shortest_distance_to_entrance_vent = 5000.0
	current_shortest_distance_to_exit_vent = 5000.0
	time_before_fast_travel = FAST_TRAVEL_DURATION
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	_patience_timer = _patience_time
	
	if data.has("do_not_reset_path") and data["do_not_reset_path"]:
		enemy.travel_to_position(enemy.nav_agent.target_position, _roaming_speed, enemy.AnimationType.WALK)
		return
	
	random_position = NavigationServer3D.map_get_random_point(_nav_map, 1, true)
	_travel_to_random_position(random_position)

func update(delta: float) -> void:
	time_before_fast_travel -= delta
	if _patience_timer >= 0.0:
		_patience_timer -= delta
	if _patience_timer <= 0.0 and enemy.is_near_light_panel and enemy.last_panel_position:
		requested_transition_to_other_state.emit("StateBreakLight", {"player_last_seen_position": enemy.last_panel_position})
	
	if _should_fast_travel(enemy.global_position, random_position) and time_before_fast_travel <= 0:
		requested_transition_to_other_state.emit("StateFastTravel",
		{"entrance_vent_location" : current_entrance_vent_location,
		"exit_vent_location" : current_exit_vent_location,
		"player_last_seen_position" : random_position,
		"exit_vent_out_position" : exit_vent_coming_out_pos,
		"state_name" : 2,})
	elif time_before_fast_travel <= 0:
		time_before_fast_travel = FAST_TRAVEL_DURATION


func physics_update(_delta: float) -> void:
	if not _map_synchronized:
		return
	
	if enemy.nav_agent.is_navigation_finished():
		random_position = NavigationServer3D.map_get_random_point(_nav_map, 1, true)
		_travel_to_random_position(random_position)
	
	if enemy.is_player_in_view():
		requested_transition_to_other_state.emit("StateChase")
	
	if enemy.player.sanity_controller.sanity <= 51.0:
		requested_transition_to_other_state.emit("StateFind")
	
	if enemy.has_heard_noise:
		var distance_to_object = enemy.global_position - enemy.object_heard_location
		if distance_to_object.length() < _hear_radius:
			requested_transition_to_other_state.emit("StateInvestigateNoise", {"player_last_seen_position": enemy.object_heard_location})
		enemy.has_heard_noise = false


func _travel_to_random_position(to: Vector3) -> void:
	enemy.travel_to_position(to, _roaming_speed, enemy.AnimationType.WALK)

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

		if d1 < current_shortest_distance_to_entrance_vent and d1 != INF:
			current_shortest_distance_to_entrance_vent = d1
			current_entrance_vent_location = vent.global_position
			first_vent = vent
	
	for vent in enemy.vents:
		if vent != first_vent and first_vent:
			var exit_child: Node3D = vent.get_child(0) as Node3D
			d2 = get_path_length(nav_map, exit_child.global_position, to)
			
			if d2 < current_shortest_distance_to_exit_vent and d2 != INF:
				current_shortest_distance_to_exit_vent = d2
				current_exit_vent_location = vent.global_position
				exit_vent_coming_out_pos = exit_child.global_position
	
	return current_shortest_distance_to_entrance_vent + current_shortest_distance_to_exit_vent

func _should_fast_travel(from: Vector3, to: Vector3) -> bool:
	return get_path_length(_nav_map, from, to) > get_best_fast_travel(_nav_map, from, to)
