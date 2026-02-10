extends Node

#this is defined on individual objects in the game

enum InteractionType {
	DEFAULT,
	DOOR,
	ROTATING_SWITCH,
	WHEEL,
	ITEM,
	HEAVY,
	NOTE,
	LOAD_SCENE,
	KEYPAD,
	BUTTON,
	REMOVABLE_TRIGGER,
	DRAWER,
}

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT
@export var maximum_rotation: float = 90.0
@export var pivot_point: Node3D
@export var nodes_to_affect: Array[Node]
@export var content: String
@export var item_data: ItemData
@export var unlock_item_name: String

var can_interact: bool = true
var is_interacting: bool = false
var lock_camera: bool = false
var starting_rotation: float
var is_front: bool
var player_hand: Marker3D
var camera: Camera3D
var previous_mouse_position: Vector2

#door variables
var door_angle: float = 0.0	
var door_velocity: float = 0.0
var door_smoothing: float = 80.0 #how heavy the door feels when opening/letting go
var door_input_active: bool = false
var door_opened: bool = false
var creak_velocity_threshold: float = 0.005
var shut_angle_threshold: float = 0.2
var shut_snap_range: float = 0.05
var creak_volume_scale: float = 1000.0
var door_fade_speed: float = 1.0
var previous_door_angle: float = 0.0
@export var is_locked: bool = false
var was_just_unlocked: bool = false
@export var reverse_door_front: bool = false
@export var flip_door_when_game_start: bool = false

#switch variables
var switch_target_rotation: float = 0.0
var switch_lerp_speed: float = 8.0
var is_switch_snapping: bool = false
var switch_moved: bool = false
var last_switch_angle: float = 0.0
var switch_creak_velocity_threshold: float = 0.01
var switch_fade_speed: float = 50.0
var switch_kickback_triggered: bool = false

#wheel variables
var wheel_kickback: float = 0.0
var wheel_kick_intensity: float = 0.1
var wheel_rotation: float = 0.0
var wheel_creak_velocity_threshold: float = 0.005
var wheel_fade_speed: float = 50.0
var last_wheel_angle: float = 0.0
var wheel_kickback_triggered: bool = false

#keypad variables
var buttons: Array[StaticBody3D]
var entered_code: Array[int]
@export var correct_code: Array[int]
var max_code_length: int = 3
var screen_label: Label3D

#Signals
signal item_collected(item: Node)
signal note_collected(node: Node3D)
signal load_new_scene(node: Node3D)
signal attract_monster(node: Node3D)

#sound effects
var last_velocity: Vector3 = Vector3.ZERO
var contact_velocity_threshold: float = 5.0
var primary_audio_player: AudioStreamPlayer3D
var secondary_audio_player: AudioStreamPlayer3D
var tertiary_audio_player: AudioStreamPlayer3D
@export var primary_sx: AudioStreamOggVorbis
@export var secondary_sx: AudioStreamOggVorbis
@export var tertiary_sx: AudioStreamOggVorbis

#weapon
@export var weapon_light: SpotLight3D
var is_flashing: bool = false
var flash_tween: Tween

#DRAWER variables
@export var maximum_drawer_distance: float = 0.4
var drawer_position: float = 0.0
var drawer_velocity: float = 0.0
var drawer_smoothing: float = 80.0
var drawer_input_active: bool = false
var starting_drawer_position: float
var previous_drawer_position: float = 0.0

func _ready() -> void:
	if flip_door_when_game_start:
		door_angle += deg_to_rad(90)

	primary_audio_player = AudioStreamPlayer3D.new()
	primary_audio_player.stream = primary_sx
	add_child(primary_audio_player)
	secondary_audio_player = AudioStreamPlayer3D.new()
	secondary_audio_player.stream = secondary_sx
	add_child(secondary_audio_player)
	tertiary_audio_player = AudioStreamPlayer3D.new()
	tertiary_audio_player.stream = tertiary_sx
	add_child(tertiary_audio_player)
	
	match interaction_type:
		InteractionType.DEFAULT:
			if object_ref.has_signal("body_entered"):
				object_ref.connect("body_entered", Callable(self, "_fire_default_collision"))
				object_ref.contact_monitor = true
				object_ref.max_contacts_reported = 1
		InteractionType.DOOR:
			starting_rotation = pivot_point.rotation.y
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
		InteractionType.ROTATING_SWITCH:
			starting_rotation = object_ref.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
		InteractionType.WHEEL:
			starting_rotation = object_ref.rotation.x
			maximum_rotation = deg_to_rad(rad_to_deg(starting_rotation)+maximum_rotation)
			camera = get_tree().get_current_scene().find_child("Camera3D", true, false)
		InteractionType.NOTE:
			content = content.replace("\\n", "\n")
		InteractionType.KEYPAD:
			screen_label = get_parent().get_node_or_null("%Screen")
			for node in get_parent().get_children():
				if node is StaticBody3D:
					buttons.append(node)
		InteractionType.DRAWER:
			starting_drawer_position = object_ref.position.z
			drawer_position = starting_drawer_position
			previous_drawer_position = drawer_position

#Runs once, when the player first clicks on an object to interact with
func preInteract(hand: Marker3D, target: Node = null) -> void:
	is_interacting = true
	match interaction_type:
		InteractionType.DEFAULT:
			player_hand = hand
		InteractionType.HEAVY:
			player_hand = hand
		InteractionType.DOOR:
			lock_camera = true
		InteractionType.ROTATING_SWITCH:
			lock_camera = true
			switch_moved = false
		InteractionType.WHEEL:
			lock_camera = true
			previous_mouse_position = get_viewport().get_mouse_position()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		InteractionType.KEYPAD:
			_press_button(target)
		InteractionType.BUTTON:
			_press_default_button(target)
		InteractionType.DRAWER:
			lock_camera = true

func _process(delta: float) -> void:
	match interaction_type:
		InteractionType.DOOR:
			
			if was_just_unlocked:
				door_velocity = 0.0
				door_input_active = false
				door_angle = starting_rotation
				pivot_point.rotation.y = starting_rotation
				was_just_unlocked = false
			else:
				if not door_input_active:
					door_velocity = lerp(door_velocity, 0.0, delta * 4.0)
					
				door_angle += door_velocity
				
				if is_locked and not flip_door_when_game_start:
					var lock_wiggle: float = 0.02
					door_angle = clamp(door_angle, starting_rotation, starting_rotation+lock_wiggle)
					pivot_point.rotation.y = door_angle
					
					if door_input_active and tertiary_sx and not tertiary_audio_player.playing and not previous_door_angle == door_angle:
						tertiary_audio_player.play()
						door_input_active = false
				elif is_locked and flip_door_when_game_start:
					var lock_wiggle: float = 0.02
					door_angle = clamp(door_angle, maximum_rotation-lock_wiggle, maximum_rotation)
					pivot_point.rotation.y = door_angle
					
					if door_input_active and tertiary_sx and not tertiary_audio_player.playing and not previous_door_angle == door_angle:
						tertiary_audio_player.play()
						door_input_active = false
				else:
					door_angle = clamp(door_angle, starting_rotation, maximum_rotation)
					pivot_point.rotation.y = door_angle
					door_input_active = false
					
					if previous_door_angle == door_angle:
						stop_door_sounds(delta)
					else:
						update_door_sounds(delta)
				
				previous_door_angle = door_angle

		InteractionType.ROTATING_SWITCH:
			if is_interacting:
				update_switch_sounds(delta)
			else:
				stop_switch_sounds(delta)

			if is_switch_snapping:
				if not switch_kickback_triggered:
					switch_kickback_triggered = true
					if secondary_sx and not secondary_audio_player.playing:
						secondary_audio_player.stop()
						secondary_audio_player.volume_db = 0.0
						secondary_audio_player.play()
				object_ref.rotation.x = lerp(object_ref.rotation.x, switch_target_rotation, delta * switch_lerp_speed)
				
				if abs(object_ref.rotation.x - switch_target_rotation) < 0.01:
					object_ref.rotation.x = switch_target_rotation
					is_switch_snapping = false
				var percentage: float = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
				notify_nodes(percentage)
				
			else:
				switch_kickback_triggered = false

		InteractionType.WHEEL:
			if is_interacting:
				update_wheel_sounds(delta)
			else:
				stop_wheel_sounds(delta)

			if abs(wheel_kickback) > 0.01:
				wheel_rotation += wheel_kickback
				wheel_kickback = lerp(wheel_kickback, 0.0, delta * 6.0)
				
				var min_wheel_rotation: float = starting_rotation / 0.1
				var max_wheel_rotation: float = maximum_rotation / 0.1
				wheel_rotation = clamp(wheel_rotation, min_wheel_rotation, max_wheel_rotation)
				
				object_ref.rotation.x = wheel_rotation * 0.1
				var percentage: float = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
				notify_nodes(percentage)
				
				if not is_interacting and not wheel_kickback_triggered:
					wheel_kickback_triggered = true
					
					if secondary_sx:
						secondary_audio_player.stop()
						secondary_audio_player.volume_db = 3.0
						secondary_audio_player.play()
			else:
				wheel_kickback_triggered = false
		
		InteractionType.DRAWER:
			if not drawer_input_active:
				drawer_velocity = lerp(drawer_velocity, 0.0, delta * 4.0)

			drawer_position += drawer_velocity
			drawer_position = clamp(
				drawer_position,
				starting_drawer_position,
				starting_drawer_position + maximum_drawer_distance
			)

			object_ref.position.z = drawer_position
			drawer_input_active = false
			previous_drawer_position = drawer_position

func _physics_process(delta: float) -> void:
	match interaction_type:
		InteractionType.DEFAULT:
			if object_ref:
				last_velocity = object_ref.linear_velocity

#Runs every frame, perform some logics on this object
func interact(player: Node3D) -> void:
	if not can_interact:
		return
	
	match interaction_type:
		InteractionType.DEFAULT:
			_default_interact()
		InteractionType.HEAVY:
			_heavy_interact()
		InteractionType.ITEM:
			_collect_item(player)
		InteractionType.NOTE:
			_collect_note(player)
		InteractionType.LOAD_SCENE:
			_trigger_load_scene()

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
					var delta: float = -event.relative.y * 0.001 if not reverse_door_front else event.relative.y * 0.001
					
					if not is_front:
						delta = -delta
						
					if abs(delta) < 0.01:
						delta *= 0.25
						
					door_velocity = lerp(door_velocity, delta, 1.0 / door_smoothing)
			InteractionType.ROTATING_SWITCH:
				if event is InputEventMouseMotion:
					var previous_angle = object_ref.rotation.x
					object_ref.rotate_x(event.relative.y * 0.001)
					object_ref.rotation.x = clamp(object_ref.rotation.x, starting_rotation, maximum_rotation)
					var percentage: float = (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
					
					if abs(object_ref.rotation.x - previous_angle) > 0.01:
						switch_moved = true
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
			InteractionType.DRAWER:
				if event is InputEventMouseMotion:
					drawer_input_active = true
					var delta = event.relative.y * 0.002
					drawer_velocity = lerp(drawer_velocity, delta, 1.0 / drawer_smoothing)

func _default_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		rigid_body_3d.set_linear_velocity((object_distance)*(5/rigid_body_3d.mass))

func _default_throw() -> void:
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		var throw_direction: Vector3 = -player_hand.global_transform.basis.z.normalized()
		var throw_strength: float = (5.0/rigid_body_3d.mass)
		rigid_body_3d.set_linear_velocity(throw_direction*throw_strength)
		can_interact = false
		await get_tree().create_timer(2.0).timeout
		can_interact = true

func _heavy_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_position
	var player_hand_position: Vector3 = player_hand.global_position
	var object_distance: Vector3 = player_hand_position - object_current_position
	if object_distance.y > 0.1:
		return
	else:
		object_distance.y = 0.0

	var distance_xz: float = object_distance.length()

	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d and distance_xz > 0.15:
		var direction: Vector3 = object_distance.normalized()

		rigid_body_3d.linear_velocity = direction * (5.0 / rigid_body_3d.mass)

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
	
func _collect_item(player: Node3D) -> void:
	if not player.inventory_controller.inventory_full:
		emit_signal("item_collected", get_parent())
		await _play_sound_effect(false, false)
		get_parent().queue_free()
	else:
		player.interaction_controller.show_item_feedback("inventory is full")

func _collect_note(player: Node3D) -> void:
	if not player.inventory_controller.inventory_full:
		var col = get_parent().find_child("CollisionShape3D", true, false)
		var mesh = get_parent().find_child("MeshInstance3D", true, false)
		if mesh:
			mesh.layers = 2
		if col:
			get_parent().remove_child(col)
			col.queue_free()
		_play_sound_effect(true, false)
		emit_signal("note_collected", get_parent())
	else:
		player.interaction_controller.show_item_feedback("inventory is full")

func _trigger_load_scene() -> void:
	_play_sound_effect(true, false)
	emit_signal("load_new_scene", get_parent())

func _play_sound_effect(visible: bool, interact: bool) -> void:
	if primary_sx:
		primary_audio_player.play()
		get_parent().visible = visible
		self.can_interact = interact
		await primary_audio_player.finished

func _fire_default_collision(node: Node) -> void:
	var impact_strength = (last_velocity - object_ref.linear_velocity).length()
	if impact_strength > contact_velocity_threshold:
		_play_sound_effect(true, true)
		emit_signal("attract_monster", get_parent())

func update_door_sounds(delta: float) -> void:
	#--CREAK LOGIC---
	var velocity_amount: float = abs(door_velocity)
	var target_volume: float = 0.0
	
	if velocity_amount > creak_velocity_threshold:
		target_volume = clamp((velocity_amount - creak_velocity_threshold) * creak_volume_scale, 0.0, 1.0)
	
	if not primary_audio_player.playing and primary_sx:
		primary_audio_player.volume_db = -80.0
		primary_audio_player.play()
	
	if primary_audio_player.playing:
		var current_volume: float = db_to_linear(primary_audio_player.volume_db)
		var new_volume: float = lerp(current_volume, target_volume, delta*door_fade_speed)
		primary_audio_player.volume_db = linear_to_db(clamp(new_volume, 0.0, 3.0))
	
	#---SHUT LOGIC---
	if abs(door_angle - starting_rotation) > shut_angle_threshold:
		door_opened = true
	
	if door_opened and abs(door_angle - starting_rotation) < shut_snap_range:
		if secondary_sx:
			secondary_audio_player.volume_db = 1.0
			secondary_audio_player.play()
			primary_audio_player.stop()
		door_opened = false

func stop_door_sounds(delta: float) -> void:
	if primary_audio_player.playing:
		var current_volume: float = db_to_linear(primary_audio_player.volume_db)
		var new_volume: float = lerp(current_volume, 0.0, delta*door_fade_speed)
		primary_audio_player.volume_db = linear_to_db(clamp(new_volume, 0.0, 1.0))
		
		if new_volume < 0.001:
			primary_audio_player.stop()

func update_switch_sounds(delta: float) -> void:
	var angular_speed = abs(object_ref.rotation.x - last_switch_angle) / max(delta, 0.0001)
	last_switch_angle = object_ref.rotation.x
	
	var target_volume: float = 0.0
	if angular_speed > switch_creak_velocity_threshold:
		target_volume = clamp((angular_speed - switch_creak_velocity_threshold) * creak_volume_scale, 0.0, 1.5)
	
	if not primary_audio_player.playing and primary_sx:
		primary_audio_player.volume_db = 0.0
		primary_audio_player.play()
	
	if primary_audio_player.playing:
		var current_vol: float = db_to_linear(primary_audio_player.volume_db)
		var new_vol: float = lerp(current_vol, target_volume, delta*switch_fade_speed)
		primary_audio_player.volume_db = linear_to_db(clamp(new_vol, 0.0, 1.5))
	
	#---ACTIVATED LOGIC---
	if switch_moved:
		if abs(object_ref.rotation.x - maximum_rotation) < 0.01 or abs(object_ref.rotation.x - starting_rotation) < 0.01:
			if secondary_sx:
				secondary_audio_player.volume_db = 0.0
				secondary_audio_player.play()
			switch_moved = false

func stop_switch_sounds(delta: float) -> void:
	if primary_audio_player.playing:
		var current_volume: float = db_to_linear(primary_audio_player.volume_db)
		var new_volume: float = lerp(current_volume, 0.0, delta*switch_fade_speed)
		primary_audio_player.volume_db = linear_to_db(clamp(new_volume, 0.0, 1.0))
		
		if new_volume < 0.001:
			primary_audio_player.stop()

func update_wheel_sounds(delta: float) -> void:
	var angular_speed = abs(object_ref.rotation.x - last_wheel_angle) / max(delta, 0.0001)
	last_wheel_angle = object_ref.rotation.x
	
	var target_volume: float = 0.0
	if angular_speed > wheel_creak_velocity_threshold:
		target_volume = clamp((angular_speed - wheel_creak_velocity_threshold) * creak_volume_scale, 0.0, 1.0)
	
	if not primary_audio_player.playing and primary_sx:
		primary_audio_player.volume_db = -15.0
		primary_audio_player.play()
	
	if primary_audio_player.playing:
		var current_vol: float = db_to_linear(primary_audio_player.volume_db)
		var new_vol: float = lerp(current_vol, target_volume, delta*wheel_fade_speed)
		primary_audio_player.volume_db = linear_to_db(clamp(new_vol, 0.0, 1.0))

func stop_wheel_sounds(delta: float) -> void:
	if primary_audio_player.playing:
		var current_volume: float = db_to_linear(primary_audio_player.volume_db)
		var new_volume: float = lerp(current_volume, 0.0, delta*wheel_fade_speed)
		primary_audio_player.volume_db = linear_to_db(clamp(new_volume, 0.0, 1.0))
		
		if new_volume < 0.001:
			primary_audio_player.stop()

func _press_default_button(target: Node) -> void:
	if target:
		var tween := create_tween()
		tween.tween_property(target, "position:z", -0.01, 0.1)
		tween.tween_property(target, "position:z", 0.0, 0.1)
	
	primary_audio_player.play()
	
	for node in nodes_to_affect:
		if node and node.has_method("execute"):
			node.call("execute")

func _press_button(target: Node) -> void:
	if target == null:
		return
	
	if target in buttons:
		var original_pos = target.position.z
		var tween := create_tween()
		tween.tween_property(target, "position:z", target.position.z-0.005, 0.1)
		tween.tween_property(target, "position:z", original_pos, 0.1)
	
	primary_audio_player.play()
	
	match target.name:
		"sbClear":
			entered_code.clear()
			screen_label.text = ""
			#screen_label.modulate = Color.WHITE
		
		"sbOk":
			if entered_code == correct_code and correct_code.size() != 0:
				screen_label.font = load("res://assets/font/creato_display/CreatoDisplay-Regular.otf")
				screen_label.font_size = 100
				screen_label.text = "CORRECT"
				screen_label.modulate = Color.GREEN
				secondary_audio_player.play()
				
				#---unclock logic---
				for node in nodes_to_affect:
					if node and node.has_method("unlock"):
						node.call("unlock")
			else:
				screen_label.font = load("res://assets/font/creato_display/CreatoDisplay-Regular.otf")
				screen_label.font_size = 100
				screen_label.text = "ERROR"
				screen_label.modulate = Color.RED
				tertiary_audio_player.play()
			
			entered_code.clear()
		
		_:
			screen_label.font = load("res://assets/font/AutoMemoryDoll-Regular.ttf.otf")
			screen_label.font_size = 150
			var letters: Array[String] = ["E", "F", "G", "H"]
			var num = str(target.name).substr(2).to_int()
			if entered_code.size() < max_code_length:
				entered_code.append(num)
				var text: String = ""
				for n in entered_code:
					text += letters[n] + " "
				screen_label.text = text
				screen_label.modulate = Color.DARK_GREEN
			else:
				print("code is full")

func unlock() -> void:
	is_locked = false
	was_just_unlocked = true
	
	match InteractionType:
		InteractionType.DOOR:
			door_velocity = 0.0
			door_input_active = false
			door_angle = starting_rotation
			pivot_point.rotation.y = starting_rotation

func relax_wheel_to_start(delta: float, speed: float = 2.0) -> void:
	if interaction_type != InteractionType.WHEEL:
		return

	var target_wheel_rotation := starting_rotation / 0.1

	wheel_rotation = move_toward(
		wheel_rotation,
		target_wheel_rotation,
		delta * speed
		)

	object_ref.rotation.x = wheel_rotation * 0.1

	var percentage := (object_ref.rotation.x - starting_rotation) / (maximum_rotation - starting_rotation)
	notify_nodes(clamp(percentage, 0.0, 1.0))

func use_item(item_data: ItemData) -> bool:
	if item_data.item_name == unlock_item_name:
		is_locked = false
		return true
	else:
		return false

func delete_removable(item_data: ItemData) -> bool:
	if item_data.item_name == unlock_item_name:
		for node in nodes_to_affect:
			if node is NavigationRegion3D:
				node.enabled = true
			elif node is Node3D:
				if node.has_method("execute"):
					node.call("execute")
				else:
					node.find_child("AnimationPlayer", true, false).play("open")
		object_ref.get_parent().queue_free()
		return true
	else:
		return false

func flash_camera() -> void:
	if is_flashing:
		return
	
	var player: Player = get_tree().get_first_node_in_group("player")
	var player_effects = player.get_node_or_null("effect_misc")
	var flash_dark_screen: ShaderMaterial = player_effects.get_child(0).get_child(0).material
	
	if flash_tween and flash_tween.is_running():
		flash_tween.kill()
	
	is_flashing = true
	weapon_light.visible = true
	weapon_light.light_color = Color.WHITE

	flash_tween = create_tween()

	var flash_count: int = 6

	for i in flash_count:

		var energy := randf_range(20.0, 28.0)
		var dark_peak := randf_range(0.6, 1.0)
		var decay := randf_range(0.01, 0.05)
		var brightness := randf_range(0.2, 0.4)
		var darkness := randf_range(0.4, 0.6)
		
		flash_tween.parallel().tween_method(
			func(v): flash_dark_screen.set_shader_parameter("darkness", v),
			0.0,
			darkness,
			0.01
		)
		
		flash_tween.parallel().tween_method(
			func(v): flash_dark_screen.set_shader_parameter("saturation", v),
			0.0,
			randf_range(0.4, 0.6),
			0.01
		)
		# Instant flash spike
		flash_tween.tween_property(weapon_light, "light_energy", energy, 0.01)
		
		flash_tween.parallel().tween_method(
			func(v): flash_dark_screen.set_shader_parameter("brightness", v),
			0.8,
			brightness,
			0.01
		)
#
		# Fade out
		flash_tween.tween_property(weapon_light, "light_energy", 0.0, decay)
		
		flash_tween.parallel().tween_method(
			func(v): flash_dark_screen.set_shader_parameter("brightness", v),
			brightness,
			0.0,
			0.05
		)
		
		flash_tween.parallel().tween_method(
			func(v): flash_dark_screen.set_shader_parameter("darkness", v),
			darkness,
			0.0,
			0.05
		)
		flash_tween.parallel().tween_method(
			func(v): flash_dark_screen.set_shader_parameter("saturation", v),
			brightness,
			randf_range(0.8, 1.0),
			0.05
		)

		# small delay between flashes
		flash_tween.tween_interval(randf_range(0.03, 0.07))

	flash_tween.tween_callback(func():
		weapon_light.visible = false
		flash_dark_screen.set_shader_parameter("darkness", 0.0)
		flash_dark_screen.set_shader_parameter("saturation", 1.0)
		flash_dark_screen.set_shader_parameter("brightness", 0.0)
		is_flashing = false
	)
