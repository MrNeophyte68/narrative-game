extends EnemyState

@export var _roaming_speed := 3.0
@export var _hear_radius := 30.0
@export var _patience_time := 10.0

var _map_synchronized := false
var _target_position: Vector3
var _nav_map: RID
var _patience_timer := 0.0


func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_map_synchronized = true
	_nav_map = enemy.get_world_3d().get_navigation_map()
	_patience_timer = _patience_time


func enter(previous_state_name: String, data := {}) -> void:
	if not _map_synchronized:
		return
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	_patience_timer = _patience_time
	
	if data.has("do_not_reset_path") and data["do_not_reset_path"]:
		enemy.travel_to_position(enemy.nav_agent.target_position, _roaming_speed, enemy.AnimationType.WALK)
		return
	_travel_to_random_position()

func update(delta: float) -> void:
	if _patience_timer >= 0.0:
		_patience_timer -= delta
	if _patience_timer <= 0.0 and enemy.is_near_light_panel and enemy.last_panel_position:
		requested_transition_to_other_state.emit("StateBreakLight", {"player_last_seen_position": enemy.last_panel_position})


func physics_update(_delta: float) -> void:
	if not _map_synchronized:
		return
	
	if enemy.nav_agent.is_navigation_finished():
		_travel_to_random_position()
	
	if enemy.is_player_in_view():
		requested_transition_to_other_state.emit("StateChase")
	
	if enemy.player.sanity_controller.sanity <= 51.0:
		requested_transition_to_other_state.emit("StateFind")
	
	if enemy.has_heard_noise:
		var distance_to_object = enemy.global_position - enemy.object_heard_location
		if distance_to_object.length() < _hear_radius:
			requested_transition_to_other_state.emit("StateInvestigateNoise", {"player_last_seen_position": enemy.object_heard_location})
		enemy.has_heard_noise = false


func _travel_to_random_position() -> void:
	var rand_pos := NavigationServer3D.map_get_random_point(_nav_map, 1, true)
	enemy.travel_to_position(rand_pos, _roaming_speed, enemy.AnimationType.WALK)
