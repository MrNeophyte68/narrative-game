extends EnemyState

var vent_entrance: Vector3
var vent_exit: Vector3
var vent_exit_out_pos: Vector3
var return_position: Vector3
var return_state: int

var entered := false
@export var _speed := 8.0

func enter(_prev: String, data := {}) -> void:
	for nav_mesh in enemy.nav_mesh_vents:
		nav_mesh.enabled = true
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	vent_entrance = data["entrance_vent_location"]
	vent_exit = data["exit_vent_location"]
	vent_exit_out_pos = data["exit_vent_out_position"]
	return_position = data["player_last_seen_position"]
	return_state = data["state_name"]

	# Go to vent entrance
	enemy.travel_to_position(vent_entrance, _speed, enemy.AnimationType.CRAWL)

func update(delta: float) -> void:
	if not entered and enemy.nav_agent.is_navigation_finished():
		_enter_vent()

func _enter_vent() -> void:
	entered = true

	enemy.nav_agent.target_position = enemy.global_position

	await get_tree().create_timer(4.0).timeout

	enemy.global_position = vent_exit

	_exit_vent()

func _exit_vent() -> void:

	enemy.travel_to_position(vent_exit_out_pos, _speed, enemy.AnimationType.CRAWL)
	
	var timeout := 0.0
	while not enemy.nav_agent.is_navigation_finished():
		timeout += get_process_delta_time()
		if timeout > 3.0:
			break
		await get_tree().process_frame
	
	entered = false

	match return_state:
		0:
			requested_transition_to_other_state.emit("StateFind")
		1:
			requested_transition_to_other_state.emit("StateInvestigateNoise", {"player_last_seen_position": return_position})
		2:
			requested_transition_to_other_state.emit("StateRoam", {"do_not_reset_path": true})
