extends Node
@onready var item_hand: Marker3D = %ItemHand
@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = %InteractionRaycast
@onready var player_camera: Camera3D = %Camera3D
@onready var hand: Marker3D = %Hand
@onready var default_reticle: TextureRect = %DefaultReticle
@onready var grab: TextureRect = %Grab
@onready var interactable_check: Area3D = $"../InteractableCheck"
@onready var outline_material: Material = preload("res://materials/outline.tres")
@onready var heavy_marker: Marker3D = %heavy_marker
@onready var note_hand: Marker3D = %NoteHand
@onready var note_overlay: Control = %NoteOverlay
@onready var note_content: RichTextLabel = %NoteContent
@onready var inventory_controller: Node = %InventoryController/CanvasLayer/InventoryUI

var current_object: Object
var last_potential_object: Object
var interaction_component: Node
var note_interaction_component: Node

var is_note_overlay_display: bool = false
var note: Node3D

var item_equipped: bool = false
var equipped_item: Node3D
var equipped_item_ic

#signals
signal change_scene(node: Node3D)
signal invent_on_item_collected(item: Node3D)

#item notification
@onready var item_notification: Label = %ItemNotification
var feedback_tween: Tween

#weapon item attribute
var last_weapon_battery_life: float
@onready var weapon_battery_life: ProgressBar = %WeaponBatteryLife
var weapon_cooldown: float = 2.0

func _ready() -> void:
	interactable_check.body_entered.connect(_on_body_entered)
	interactable_check.body_exited.connect(_on_body_exited)
	invent_on_item_collected.connect(inventory_controller.pickup_item)
	#default_reticle.position.x = get_viewport().size.x / 2 - default_reticle.texture.get_size().x / 2
	#default_reticle.position.y = get_viewport().size.y / 2 - default_reticle.texture.get_size().y / 2
	#grab.position.x = get_viewport().size.x / 2 - grab.texture.get_size().x / 2
	#grab.position.y = get_viewport().size.y / 2 - grab.texture.get_size().y / 2
	default_reticle.position.x = 960 - grab.texture.get_size().x / 2
	default_reticle.position.y = 540 - grab.texture.get_size().y / 2
	grab.position.x = 960 - grab.texture.get_size().x / 2
	grab.position.y = 540 - grab.texture.get_size().y / 2
	item_notification.position.x = 960
	item_notification.position.y = 900
	weapon_battery_life.position.y = 1020
	

func _process(delta: float) -> void:
	if equipped_item:
		if item_equipped and equipped_item_ic.item_data.action_data.action_type == equipped_item_ic.item_data.action_data.ActionType.WEAPON:
			weapon_battery_life.visible = true
			weapon_battery_life.value = equipped_item_ic.item_data.action_data.max_battery_life
		else:
			weapon_battery_life.visible = false
	else:
		weapon_battery_life.visible = false

	if inventory_controller.visible == false:
		if interaction_component and interaction_component.is_interacting:
			default_reticle.visible = false
			grab.visible = false
		
		#if on the previous frame, we were interacting with an object, let's keep interacting with it
		if current_object:
		
			if player_camera.global_transform.origin.distance_to(current_object.global_transform.origin) > 3.0:
				if interaction_component:
					interaction_component.postInteract()
				current_object = null
				_unfocus()
		
			if Input.is_action_just_pressed("secondary"):
				if interaction_component:
					interaction_component.auxInteract()
					current_object = null
					_unfocus()
			elif Input.is_action_pressed("primary"):
				if interaction_component:
					interaction_component.interact(get_parent())
			else:
				if interaction_component:
					interaction_component.postInteract()
					current_object = null
					_unfocus()
		else: #we weren't interacting with something, let's see if we can
			var potential_object: Object = interaction_raycast.get_collider()
			
			if potential_object and potential_object is Node:
				var node: Node = potential_object
				interaction_component = null
				while node:
					interaction_component = node.get_node_or_null("InteractionComponent")
					if interaction_component:
						break
					node = node.get_parent()
				if interaction_component:
					if interaction_component.can_interact == false:
						return
					
					last_potential_object = potential_object
					_focus()
					if Input.is_action_just_pressed("primary"):
						current_object = potential_object
						if interaction_component.interaction_type != interaction_component.InteractionType.HEAVY:
							interaction_component.preInteract(hand, current_object)
						else:
							interaction_component.preInteract(heavy_marker, current_object)
						
						if interaction_component.interaction_type == interaction_component.InteractionType.ITEM:
							interaction_component.connect("item_collected", Callable(self, "_on_item_collected"))
						
						if interaction_component.interaction_type == interaction_component.InteractionType.NOTE:
							interaction_component.connect("note_collected", Callable(self, "_on_note_inspected"))
						
						if interaction_component.interaction_type == interaction_component.InteractionType.LOAD_SCENE:
							interaction_component.connect("load_new_scene", Callable(self, "_on_load_new_scene"))
						
						if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
							interaction_component.set_direction(current_object.to_local(interaction_raycast.get_collision_point()))
				else:
					_unfocus()
			else:
				_unfocus()
	else:
		default_reticle.visible = false
		grab.visible = false
		current_object = null

func _physics_process(delta: float) -> void:
	if weapon_cooldown >= 0.0:
		weapon_cooldown -= delta
	if item_equipped and Input.is_action_pressed("secondary") and equipped_item_ic.item_data.action_data.action_type == equipped_item_ic.item_data.action_data.ActionType.WEAPON and inventory_controller.visible == false:
		if get_parent().player_state != get_parent().PlayerState.IDLE_STAND:
			return
		if player_camera.fov >= 81.0:
			player_camera.fov = lerp(player_camera.fov, 80.0, delta*0.8)
		if equipped_item_ic.item_data.action_data.passive_draining and equipped_item_ic.item_data.action_data.max_battery_life > 0.0:
			_use_weapon_item(delta)
		elif item_equipped and Input.is_action_just_pressed("primary") and equipped_item_ic.item_data.action_data.action_type == equipped_item_ic.item_data.action_data.ActionType.WEAPON and equipped_item_ic.item_data.action_data.max_battery_life > 0.0 and not equipped_item_ic.item_data.action_data.passive_draining:
			_use_weapon_item(delta)
	else:
		player_camera.fov = lerp(player_camera.fov, 90.0, delta*5)
		

func _input(event: InputEvent) -> void:
	if is_note_overlay_display and event.is_action_pressed("primary"):
		_on_note_collected()
	
	if item_equipped and Input.is_action_just_pressed("primary") and equipped_item_ic.item_data.action_data.action_type == equipped_item_ic.item_data.action_data.ActionType.EQUIPPABLE:
		_use_equipped_item()
	elif item_equipped and (Input.is_action_just_pressed("secondary") or Input.is_action_just_pressed("interaction")) and equipped_item_ic.item_data.action_data.action_type == equipped_item_ic.item_data.action_data.ActionType.EQUIPPABLE:
		equipped_item.queue_free()
		item_equipped = false
	elif item_equipped and Input.is_action_just_pressed("interaction") and equipped_item_ic.item_data.action_data.action_type == equipped_item_ic.item_data.action_data.ActionType.WEAPON:
		equipped_item.queue_free()
		item_equipped = false

func _on_note_inspected(_note: Node3D) -> void:
	note = _note
	
	if note.get_parent() != null:
		note.get_parent().remove_child(note)
	else:
		var mesh = note.find_child("MeshInstance3D", true, false)
		if mesh:
			mesh.layers = 2
		var mesh1 = note.find_child("MeshInstance3D1", true, false)
		if mesh1:
			mesh1.layers = 2
		var mesh2 = note.find_child("minutes", true, false)
		if mesh2:
			mesh2.layers = 2
		var col = note.find_child("CollisionShape3D", true, false)
		if col:
			col.get_parent().remove_child(col)
			col.queue_free()
	
	note_hand.add_child(note)
	note.transform.origin = note_hand.transform.origin
	note.position = Vector3(0.0, 0.0, 0.0)
	note.rotation_degrees = Vector3(90, 10, 0)
	
	if note.name != "Clock":
		note_overlay.visible = true
		is_note_overlay_display = true
		note_interaction_component = note.get_node_or_null("InteractionComponent")
		note_content.bbcode_enabled = true
		note_content.text = note_interaction_component.content
		return

	is_note_overlay_display = true
	note_interaction_component = note.get_node_or_null("InteractionComponent")

func _on_item_equipped(item: Node3D) -> void:
	if item_hand.get_child(0):
		item_hand.get_child(0).queue_free()
	if item is RigidBody3D:
		item.freeze = true
		item.linear_velocity = Vector3.ZERO
		item.angular_velocity = Vector3.ZERO
		item.gravity_scale = 0.0
	if item.get_parent() != null:
		item.get_parent().remove_child(item)
	else:
		if item.get_node_or_null("InteractionComponent").item_data.action_data.action_type != item.get_node_or_null("InteractionComponent").item_data.action_data.ActionType.WEAPON:
			var mesh = item.find_child("MeshInstance3D", true, false)
			if mesh.find_child("MeshInstance3D", true, false):
				var second_mesh = mesh.find_child("MeshInstance3D", true, false)
				if second_mesh:
					second_mesh.layers = 2
			if mesh:
				mesh.layers = 2
		var col = item.find_child("CollisionShape3D", true, false)
		if col:
			col.get_parent().remove_child(col)
			col.queue_free()
	
	item_hand.add_child(item)
	item.transform.origin = item_hand.transform.origin
	item.position = Vector3(0.0, 0.0, 0.0)
	item.rotation_degrees = Vector3(90, 90, 0)
	
	item_equipped = true
	equipped_item = item
	equipped_item_ic = equipped_item.get_node_or_null("InteractionComponent")

	match equipped_item_ic.item_data.action_data.modifier_name:
			"camera":
				if not equipped_item_ic.item_data.action_data.is_upgraded:
					weapon_battery_life.max_value = 2.0
					weapon_battery_life.value = equipped_item_ic.item_data.action_data.max_battery_life
				else:
					weapon_battery_life.max_value = 3.0
					weapon_battery_life.value = equipped_item_ic.item_data.action_data.max_battery_life
			"walkie_talkie":
				if not equipped_item_ic.item_data.action_data.is_upgraded:
					weapon_battery_life.max_value = 100.0
					weapon_battery_life.value = equipped_item_ic.item_data.action_data.max_battery_life
				else:
					weapon_battery_life.max_value = 200.0
					weapon_battery_life.value = equipped_item_ic.item_data.action_data.max_battery_life
				

func _use_equipped_item() -> void:
	if last_potential_object:
		if interaction_component:
			if interaction_component.has_method("use_item") and interaction_component.interaction_type == interaction_component.InteractionType.DOOR and interaction_component.is_locked:
				if interaction_component.use_item(equipped_item_ic.item_data):
					if equipped_item_ic.item_data.action_data.one_time_use:
						show_item_feedback(equipped_item_ic.item_data.action_data.success_text)
						inventory_controller.discard_item(inventory_controller.last_equipped_slot_id)
						equipped_item.queue_free()
						item_equipped = false
						return
				else:
					show_item_feedback("item cannot be used here")
			elif interaction_component.has_method("delete_removable") and interaction_component.interaction_type == interaction_component.InteractionType.REMOVABLE_TRIGGER:
				if interaction_component.delete_removable(equipped_item_ic.item_data):
					if equipped_item_ic.item_data.action_data.one_time_use:
						show_item_feedback(equipped_item_ic.item_data.action_data.success_text)
						inventory_controller.discard_item(inventory_controller.last_equipped_slot_id)
						equipped_item.queue_free()
						item_equipped = false
						return
					else:
						show_item_feedback(equipped_item_ic.item_data.action_data.success_text)
						return
				else:
					show_item_feedback("item cannot be used here")
	else:
		print("nothing to use item on")

func _use_weapon_item(delta: float) -> void:
	match equipped_item_ic.item_data.action_data.modifier_name:
		"camera":
			if weapon_cooldown > 0.0:
				return
			equipped_item_ic.item_data.action_data.max_battery_life -= 1.0
			equipped_item_ic.item_data.action_data.max_battery_life = clamp(equipped_item_ic.item_data.action_data.max_battery_life, 0.0, 2.0 if not equipped_item_ic.item_data.action_data.is_upgraded else 3.0)
			equipped_item_ic.flash_camera()
			weapon_cooldown = 2.0
		"walkie_talkie":
			equipped_item_ic.item_data.action_data.max_battery_life -= delta*2.0
			equipped_item_ic.item_data.action_data.max_battery_life = clamp(equipped_item_ic.item_data.action_data.max_battery_life, 0.0, 100.0 if not equipped_item_ic.item_data.action_data.is_upgraded else 200.0)
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if enemy.is_player_close(25.0):
					equipped_item_ic.item_data.action_data.is_on = true
				else:
					equipped_item_ic.item_data.action_data.is_on = false

func isCameraLocked() -> bool:
	if interaction_component:
		if interaction_component.lock_camera and interaction_component.is_interacting:
			return true
	return false

func _focus() -> void:
	default_reticle.visible = false
	grab.visible = true

func _unfocus() -> void:
	default_reticle.visible = true
	grab.visible = false

func _on_load_new_scene(node: Node3D):
	get_parent().animation_player.play("fade_in")
	await get_parent().animation_player.animation_finished
	emit_signal("change_scene", get_parent())

func _on_item_collected(item: Node):
	#Inventory system
	item.visible = false
	var ic = item.get_node_or_null("InteractionComponent")
	_add_item_to_inventory(ic.item_data)
	await ic.primary_audio_player.finished
	item.queue_free()

func _add_item_to_inventory(item_data: ItemData) -> void:
	if item_data != null:
		invent_on_item_collected.emit(item_data)
		return
	
	print("ItemData not found")

func _on_note_collected():
	note_overlay.visible = false
	is_note_overlay_display = false
	if note_interaction_component.secondary_audio_player:
		var audio_player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		audio_player.stream = note_interaction_component.secondary_audio_player.stream
		add_child(audio_player)
		audio_player.play()
		note.visible = false
		_add_item_to_inventory(note_interaction_component.item_data)
		#await audio_player.finished
		note.queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.name != "Player":
		var int_comp = body.get_node_or_null("InteractionComponent")
		if int_comp and int_comp.interaction_type == int_comp.InteractionType.ITEM:
			var mesh: MeshInstance3D = body.find_child("MeshInstance3D", true, false)
			mesh.material_overlay = outline_material
			if mesh.get_child(0):
				mesh.get_child(0).material_overlay = outline_material

func _on_body_exited(body: Node3D) -> void:
	if body.name != "Player":
		var mesh: MeshInstance3D = body.find_child("MeshInstance3D", true, false)
		if mesh:
			mesh.material_overlay = null

func show_item_feedback(text: String, duration := 1.5) -> void:
	if feedback_tween and feedback_tween.is_running():
		feedback_tween.kill()

	item_notification.text = text
	item_notification.visible = true
	item_notification.modulate.a = 0.0

	feedback_tween = create_tween()
	feedback_tween.tween_property(item_notification, "modulate:a", 1.0, 0.15)
	feedback_tween.tween_interval(duration)
	feedback_tween.tween_property(item_notification, "modulate:a", 0.0, 0.25)
	feedback_tween.tween_callback(func():
		item_notification.visible = false
	)
