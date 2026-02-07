extends CharacterBody3D
class_name Enemy

signal reached_player
@export var max_spotting_distance : float = 50.0
@export var vents: Array[Node3D]
@export var nav_mesh_vents: Array[NavigationRegion3D]
var _current_speed : float = 0.0
@onready var nav_agent: NavigationAgent3D = %NavigationAgent3D
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var eyes: Node3D = %Eyes
@onready var eye_ray_cast: RayCast3D = %EyeRayCast
@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var enemy_debug: Label = %EnemyDebug
@onready var state_machine: StateMachine = %StateMachine
var has_heard_noise: bool = false
var is_near_light_panel: bool = false
var object_heard_location: Vector3
var last_panel_position: Vector3

enum AnimationType {
	RUN,
	WALK,
	BREAK,
	CRAWL,
}

func _ready() -> void:
	set_physics_process(false)
	await get_tree().physics_frame
	set_physics_process(true)
	
	for object in get_parent().get_children():
		if object and object is RigidBody3D:
			for node in object.get_children():
				if node and node.has_signal("attract_monster"):
					var ic = node
					if ic.interaction_type == ic.InteractionType.DEFAULT:
						ic.connect("attract_monster", Callable(self, "_go_to_noise"))

func _process(delta: float) -> void:
	enemy_debug.text = "Player Found: %s\nCurrent Enemy State: %s\nPatience Time: %.2f\nNear Panel: %s\nTime Before FT: %.2f" % [
		is_player_in_view(),
		state_machine.state.name,
		state_machine.state._patience_timer if state_machine.state.name == "StateRoam" else -1.0,
		is_near_light_panel,
		state_machine.state.time_before_fast_travel if state_machine.state.name == "StateRoam" else -1.0,
	]

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished() and state_machine.state.name != "StateBreakLight":
		animation_player.play("idle", 0.2)
		return
	
	var next_path_position : Vector3 = nav_agent.get_next_path_position()
	var where_to_look := next_path_position
	where_to_look.y = global_position.y
	if not where_to_look.is_equal_approx(global_position):
		# if you want interpolation, look into quaternions and slerp()
		# I'm just using look_at for simplicity
		if not animation_player.current_animation == "break":
			look_at(where_to_look)
		else:
			_current_speed = 0.0
	
	var direction := next_path_position - global_position
	direction.y = 0.0
	direction = direction.normalized()
	velocity = direction * _current_speed
	move_and_slide()

func is_player_close(stun_radius: float) -> bool:
	var distance_to_player = global_position - player.global_position
	if distance_to_player.length() < stun_radius:
		return true
	return false

func travel_to_position(wanted_position: Vector3, speed: float, play_run_anim: AnimationType) -> void:
	nav_agent.target_position = wanted_position
	_current_speed = speed
	
	if play_run_anim == AnimationType.RUN:
		animation_player.play("zombie_run", 0.2)
	elif play_run_anim == AnimationType.WALK:
		animation_player.play("walk1", 0.2)
	elif play_run_anim == AnimationType.CRAWL:
		animation_player.play("crawl", 0.2)

func is_player_in_view() -> bool:
	var vec_to_player : Vector3 = (player.global_position - global_position)
	
	if vec_to_player.length() > max_spotting_distance:
		return false
	
	var in_fov : bool = -eyes.global_basis.z.normalized().dot(vec_to_player.normalized()) > 0.3
	
	if in_fov:
		return not is_line_of_sight_broken()
	
	return false

func is_line_of_sight_broken() -> bool:
	eye_ray_cast.target_position = eye_ray_cast.to_local(player.global_position + Vector3(0, 1.5, 0))
	eye_ray_cast.force_raycast_update()
	if eye_ray_cast.get_collider():
		if eye_ray_cast.get_collider().is_in_group("player"):
			return false
	return eye_ray_cast.is_colliding()

func _go_to_noise(node: Node3D) -> void:
	has_heard_noise = true
	object_heard_location = node.global_position
