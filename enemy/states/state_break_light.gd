extends EnemyState

@export var _speed := 8.0
var _player_last_seen_position: Vector3


func enter(previous_state_name: String, data := {}) -> void:
	enemy.nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	if data["player_last_seen_position"]:
		_player_last_seen_position = data["player_last_seen_position"]
	else:
		printerr("State 'Searching' was not given the player's last seen position through the data dictionary.")
		
	_go_to_panel_last_seen_position()

func physics_update(_delta: float) -> void:
	if enemy.nav_agent.is_navigation_finished():
		enemy.animation_player.play("break", 0.2)
		await enemy.animation_player.animation_finished
		requested_transition_to_other_state.emit("StateRoam")


func _go_to_panel_last_seen_position() -> void:
	var target_position := _player_last_seen_position
	enemy.travel_to_position(target_position, _speed, enemy.AnimationType.RUN)
