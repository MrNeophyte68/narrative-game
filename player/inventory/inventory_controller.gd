extends Control
class_name InventoryController
@onready var interaction_controller: Node = $"../../../InteractionController"
@onready var sanity_controller: Node = $"../../../SanityController"
@onready var context_menu: PopupMenu = %ContextMenu
@onready var player_camera: Camera3D = $"../../../head/eyes/Camera3D"
@onready var hand: Marker3D = $"../../../head/eyes/Camera3D/Hand"
var item_slots_count: int = 15
var inventory_slot_prefab: PackedScene = load("res://player/inventory/InventorySlot.tscn")
@onready var inventory_grid: GridContainer = %GridContainer
var inventory_slots: Array[InventorySlot] = []
var inventory_full: bool = false
var last_equipped_slot_id: int
@onready var item_hand: Marker3D = $"../../../head/eyes/SubViewportContainer/SubViewport/NoteCamera/ItemHand"

@onready var pill_bottle: PackedScene = load("res://objects/items/pill_bottle.tscn")
@onready var basic_note: PackedScene = load("res://objects/basic_note.tscn")
@onready var basic_key: PackedScene = load("res://objects/items/basic_key.tscn")
@onready var crowbar: PackedScene = load("res://objects/items/crowbar.tscn")
@onready var camera: PackedScene = load("res://objects/items/camera.tscn")
@onready var battery: PackedScene = load("res://objects/items/battery.tscn")
@onready var vhs_tape: PackedScene = load("res://objects/items/vhs_tape.tscn")
@onready var terminal_circuit: PackedScene = load("res://objects/items/terminal_circuit.tscn")
@onready var small_key: PackedScene = load("res://objects/items/small_key.tscn")
@onready var walkie_talkie: PackedScene = load("res://objects/items/talkie_walkie.tscn")

func _ready() -> void:
	for i in item_slots_count:
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		inventory_grid.add_child(slot)
		slot.inventory_slot_id = i
		slot.on_item_swapped.connect(_on_item_swapped_on_slot)
		slot.on_item_doubled_clicked.connect(_on_item_doubled_clicked)
		slot.on_item_right_clicked.connect(_on_item_right_clicked)
		inventory_slots.append(slot)
	
	context_menu.connect("id_pressed", Callable(self, "on_context_menu_selected"))

func has_free_slot() -> bool:
	for slot in inventory_slots:
		if slot.slot_data == null:
			return true
	return false

func has_battery_in_inventory() -> bool:
	for slot in inventory_slots:
		if slot.slot_data:
			if slot.slot_data.item_name == "battery":
				slot.fill_slot(null)
				return true
	return false

func pickup_item(item_data: ItemData) -> void:
	for slot in inventory_slots:
		if not slot.slot_filled:
			slot.fill_slot(item_data)
			inventory_full = not has_free_slot()
			return
	inventory_full = true

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var slot: InventorySlot = inventory_slots[data]
	if slot.slot_data == null:
		return false
	return true

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data == last_equipped_slot_id:
		if item_hand.get_child(0):
			item_hand.get_child(0).queue_free()
			interaction_controller.item_equipped = false
	drop_collectable(data)
	inventory_full = not has_free_slot()

func _on_item_swapped_on_slot(from_slot_id: int, to_slot_id: int) -> void:
	var to_slot_item: ItemData = inventory_slots[to_slot_id].slot_data
	var from_slot_item: ItemData = inventory_slots[from_slot_id].slot_data
	inventory_slots[to_slot_id].fill_slot(from_slot_item)
	inventory_slots[from_slot_id].fill_slot(to_slot_item)
	if from_slot_id != to_slot_id:
		last_equipped_slot_id = to_slot_id
	

func _on_item_doubled_clicked(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			use_collectable(slot_id)
		ActionData.ActionType.EQUIPPABLE:
			equip_collectable(slot_id)
		ActionData.ActionType.INSPECTABLE:
			view_inspectable(slot_id)
		ActionData.ActionType.WEAPON:
			equip_collectable(slot_id)

func _on_item_right_clicked(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	context_menu.clear()
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			context_menu.add_item("Use", 0)
			context_menu.add_item("Drop", 1)
		ActionData.ActionType.EQUIPPABLE:
			if slot.slot_data.action_data.modifier_name != "small_key":
				context_menu.add_item("Equip", 0)
				context_menu.add_item("Drop", 1)
			else:
				context_menu.add_item("Equip", 0)
		ActionData.ActionType.INSPECTABLE:
			context_menu.add_item("Read", 0)
			context_menu.add_item("Discard", 1)
		ActionData.ActionType.WEAPON:
			context_menu.add_item("Equip", 0)
			context_menu.add_item("Recharge", 1)
			context_menu.add_item("Drop", 2)
		_:
			context_menu.add_item("Drop", 0)

	context_menu.set_meta("slot_id", slot_id)
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var rect: Rect2i = Rect2i(mouse_pos.floor(), Vector2i(1,1))
	context_menu.popup(rect)

func on_context_menu_selected(id: int) -> void:
	var slot_id = context_menu.get_meta("slot_id")
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			match id:
				0:
					use_collectable(slot_id)
				1:
					drop_collectable(slot_id)
		ActionData.ActionType.EQUIPPABLE:
			match id:
				0:
					equip_collectable(slot_id)
				1:
					drop_collectable(slot_id)
		ActionData.ActionType.INSPECTABLE:
			match id:
				0:
					view_inspectable(slot_id)
				1:
					discard_item(slot_id)
		ActionData.ActionType.WEAPON:
			match id:
				0:
					equip_collectable(slot_id)
				1:
					recharge_weapon(slot_id)
				2:
					drop_collectable(slot_id)
		_:
			match id:
				0:
					drop_collectable(slot_id)

func _get_item_action_type(item_data: ItemData) -> ActionData.ActionType:
	if not item_data or not item_data.item_model_prefab == null:
		return ActionData.ActionType.INVALID
	
	return item_data.action_data.action_type

func discard_item(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	slot.fill_slot(null)
	inventory_full = not has_free_slot()

func use_collectable(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	var action_data: ActionData = slot.slot_data.action_data
	match action_data.modifier_name:
		"pill_bottle":
			sanity_controller.add_sanity(action_data.modifier_value)
	
	inventory_full = not has_free_slot()
	slot.fill_slot(null)

func drop_collectable(slot_id: int) -> void:
	var instance
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	if slot.slot_data.action_data.modifier_name != "small_key":
		if slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.CONSUMABLE:
			match slot.slot_data.action_data.modifier_name:
				"pill_bottle":
					instance = pill_bottle.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
		elif slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.EQUIPPABLE:
			match slot.slot_data.action_data.modifier_name:
				"basic_key":
					instance = basic_key.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
				"crowbar":
					instance = crowbar.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
				"vhs_tape":
					instance = vhs_tape.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
				"terminal_circuit":
					instance = terminal_circuit.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
		elif slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.WEAPON:
			match slot.slot_data.action_data.modifier_name:
				"camera":
					instance = camera.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
				"walkie_talkie":
					instance = walkie_talkie.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
					instance.get_node_or_null("InteractionComponent").item_data.action_data.max_battery_life = slot.slot_data.action_data.max_battery_life
		elif slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.INSPECTABLE:
			discard_item(slot_id)
			return
		else:
			match slot.slot_data.item_name:
				"battery":
					instance = battery.instantiate() as Node3D
					get_tree().current_scene.add_child(instance)
		
		if item_hand.get_child(0):
			item_hand.get_child(0).queue_free()
			interaction_controller.item_equipped = false
		
		var drop_distance: float = 2.0
		var forward_dir: Vector3 = -player_camera.global_transform.basis.z.normalized()
		var target_pos: Vector3 = player_camera.global_transform.origin + forward_dir * drop_distance
		var space_state = hand.get_world_3d().direct_space_state
		
		var obstacle_params = PhysicsRayQueryParameters3D.new()
		obstacle_params.from = player_camera.global_transform.origin
		obstacle_params.to = target_pos
		obstacle_params.exclude = [hand.get_parent()]
		
		var obstacle_hit: Dictionary = space_state.intersect_ray(obstacle_params)
		if obstacle_hit:
			print("cant drop here")
			return
		
		var ground_params = PhysicsRayQueryParameters3D.new()
		ground_params.from = target_pos + Vector3.UP * 2.0
		ground_params.to = target_pos - Vector3.UP * 5.0
		ground_params.exclude = [hand.get_parent()]
		
		var ground_hit: Dictionary = space_state.intersect_ray(ground_params)
		if not ground_hit:
			print("missing ground to drop")
			return
		
		var ground_pos: Vector3 = ground_hit.position
		var buffer_height: float = 1.2
		if instance is RigidBody3D:
			instance.global_transform.origin = ground_pos + Vector3.UP * buffer_height
			instance.freeze = false
			instance.gravity_scale = 1.0
		else:
			instance.global_transform.origin = ground_pos + Vector3.UP * 0.001
		
		instance.rotation_degrees.y = randf() * 360
		instance.rotation_degrees.x = randf() * 90
		slot.fill_slot(null)
		inventory_full = not has_free_slot()

func view_inspectable(slot_id: int) -> void:
	var instance
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	if slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.INSPECTABLE:
		match slot.slot_data.action_data.modifier_name:
			"basic_note":
				instance = basic_note.instantiate() as Node3D
				interaction_controller._on_note_inspected(instance)
				slot.fill_slot(null)

func equip_collectable(slot_id: int) -> void:
	var instance
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	last_equipped_slot_id = slot_id
	
	if slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.EQUIPPABLE:
		match slot.slot_data.action_data.modifier_name:
			"basic_key":
				instance = basic_key.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)
			"crowbar":
				instance = crowbar.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)
			"vhs_tape":
				instance = vhs_tape.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)
			"terminal_circuit":
				instance = terminal_circuit.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)
			"small_key":
				instance = small_key.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)
	elif slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.WEAPON:
		match slot.slot_data.action_data.modifier_name:
			"camera":
				instance = camera.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)
			"walkie_talkie":
				instance = walkie_talkie.instantiate() as Node3D
				interaction_controller._on_item_equipped(instance)

func recharge_weapon(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	if slot.slot_data.action_data.action_type == slot.slot_data.action_data.ActionType.WEAPON:
		match slot.slot_data.action_data.modifier_name:
			"camera":
				if has_battery_in_inventory():
					if not slot.slot_data.action_data.is_upgraded:
						slot.slot_data.action_data.max_battery_life = 2.0
					else:
						slot.slot_data.action_data.max_battery_life = 3.0
			"walkie_talkie":
				if has_battery_in_inventory():
					if not slot.slot_data.action_data.is_upgraded:
						slot.slot_data.action_data.max_battery_life = 100.0
					else:
						slot.slot_data.action_data.max_battery_life = 200.0
