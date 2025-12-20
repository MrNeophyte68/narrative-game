extends Node

#this is defined on individual objects in the game

enum InteractionType {
	DEFAULT,
	DOOR,
	ROTATING_SWITCH,
	WHEEL,
	ITEM
}

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT
@export var maximum_rotation: float = 90.0
@export var pivot_point: Node3D
@export var nodes_to_affect: Array[Node]

var can_interact: bool = true
var is_interacting: bool = false
var lock_camera: bool = false
var starting_rotation: float
var is_front: bool
var player_hand: Marker3D
var camera: Camera3D
var previous_mouse_position: Vector2
var wheel_rotation: float = 0.0

#door variables
var door_angle: float = 0.0
var door_velocity: float = 0.0
var door_smoothing: float = 80.0 #how heavy the door feels when opening/letting go
var door_input_active: bool = false

#switch variables
var switch_target_rotation: float = 0.0
var switch_lerp_speed: float = 8.0
var is_switch_snapping: bool = false

#wheel variables
var wheel_kickback: float = 0.0
var wheel_kick_intensity: float = 0.1

#Signals
signal item_collected(item: Node)

func _ready() -> void:
	match interaction_type:
		InteractionType.DOOR:
			starting_rotation = pivot_point.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
		InteractionType.ROTATING_SWITCH:
			starting_rotation = object_ref.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
		InteractionType.WHEEL:
			starting_rotation = object_ref.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
			camera = get_tree().get_current_scene().find_child("Camera3D", true, false)
			
			

#Runs once, when the player first clicks on an object to interact with
func preInteract(hand: Marker3D) -> void:
	is_interacting = true
	match interaction_type:
		InteractionType.DEFAULT:
			player_hand = hand
		InteractionType.DOOR:
			lock_camera = true
		InteractionType.ROTATING_SWITCH:
			lock_camera = true
		InteractionType.WHEEL:
			lock_camera = true
			previous_mouse_position = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	match interaction_type:
		InteractionType.DOOR:
			if not door_input_active:
				door_velocity = lerp(door_velocity, 0.0, delta * 4.0)
			door_angle += door_velocity
			door_angle = clamp(door_angle, starting_rotation, maximum_rotation)
			pivot_point.rotation.y = door_angle
			door_input_active = false
		InteractionType.ROTATING_SWITCH:
			if is_switch_snapping:
				object_ref.rotation.x = lerp(object_ref.rotation.x, switch_target_rotation, delta * switch_lerp_speed)
				if abs(object_ref.rotation.x - switch_target_rotation) < 0.01:
					object_ref.rotation.x = switch_target_rotation
					is_switch_snapping = false
				var percentage: float = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
				notify_nodes(percentage)
		InteractionType.WHEEL:
			if abs(wheel_kickback) > 0.01:
				wheel_rotation += wheel_kickback
				wheel_kickback = lerp(wheel_kickback, 0.0, delta * 6.0)
				
				var min_wheel_rotation: float = starting_rotation / 0.1
				var max_wheel_rotation: float = maximum_rotation / 0.1
				wheel_rotation = clamp(wheel_rotation, min_wheel_rotation, max_wheel_rotation)
				
				object_ref.rotation.x = wheel_rotation * 0.1
				var percentage: float = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
				notify_nodes(percentage)

#Runs every frame, perform some logics on this object
func interact() -> void:
	if not can_interact:
		return
	
	match interaction_type:
		InteractionType.DEFAULT:
			_default_interact()
		InteractionType.ITEM:
			_collect_item()

func auxInteract() -> void:
	if not can_interact:
		return
	
	match interaction_type:
		InteractionType.DEFAULT:
			_default_throw()

#Runs once, when the player last interacts with an object
func postInteract() -> void:
	is_interacting = false
	lock_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	match interaction_type:
		InteractionType.ROTATING_SWITCH:
			var percentage: float = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
			if percentage < 0.3:
				switch_target_rotation = starting_rotation
				is_switch_snapping = true
			elif percentage > 0.7:
				switch_target_rotation = maximum_rotation
				is_switch_snapping = true
		InteractionType.WHEEL:
			wheel_kickback = -sign(wheel_rotation) * wheel_kick_intensity

func _input(event: InputEvent) -> void:
	if is_interacting:
		match interaction_type:
			InteractionType.DOOR:
				if event is InputEventMouseMotion:
					door_input_active = true
					var delta: float = -event.relative.y * 0.001
					
					if not is_front:
						delta = -delta
						
					if abs(delta) < 0.01:
						delta *= 0.25
						
					door_velocity = lerp(door_velocity, delta, 1.0 / door_smoothing)
			InteractionType.ROTATING_SWITCH:
				if event is InputEventMouseMotion:
					var percentage: float
					object_ref.rotate_x(event.relative.y * 0.001)
					object_ref.rotation.x = clamp(object_ref.rotation.x, starting_rotation, maximum_rotation)
					percentage = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
					notify_nodes(percentage)
			InteractionType.WHEEL:
				if event is InputEventMouseMotion:
					var percentage: float
					var mouse_position: Vector2 = event.position
					
					if calculate_cross_product(mouse_position) < 0:
						wheel_rotation += 0.2
					else:
						wheel_rotation -= 0.2
						
					object_ref.rotation.x = wheel_rotation * 0.1
					object_ref.rotation.x = clamp(object_ref.rotation.x, starting_rotation, maximum_rotation)
					percentage = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
					previous_mouse_position = mouse_position
					var min_wheel_rotation: float = starting_rotation / 0.1
					var max_wheel_rotation: float = maximum_rotation / 0.1
					wheel_rotation = clamp(wheel_rotation, min_wheel_rotation, max_wheel_rotation)
					notify_nodes(percentage) 

func _default_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		rigid_body_3d.set_linear_velocity((object_distance)*(5/rigid_body_3d.mass))

func _default_throw() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		var throw_direction: Vector3 = -player_hand.global_transform.basis.z.normalized()
		var throw_strength: float = (20.0/rigid_body_3d.mass)
		rigid_body_3d.set_linear_velocity(throw_direction*throw_strength)
		can_interact = false
		await get_tree().create_timer(2.0).timeout
		can_interact = true

func set_direction(_normal: Vector3) -> void:
	if _normal.z > 0:
		is_front = true
	else:
		is_front = false

func notify_nodes(percentage: float) -> void:
	for node in nodes_to_affect:
		if node and node.has_method("execute"):
			node.call("execute", percentage)

func calculate_cross_product(_mouse_position: Vector2) -> float:
	var center_position = camera.unproject_position(object_ref.global_transform.origin)
	var vector_to_previous = previous_mouse_position - center_position
	var vector_to_current = _mouse_position - center_position
	var cross_product = vector_to_current.x * vector_to_previous.y - vector_to_current.y * vector_to_previous.x
	return cross_product
	
func _collect_item() -> void:
	emit_signal("item_collected", get_parent())
	get_parent().queue_free()
