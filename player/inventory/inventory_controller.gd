extends Control
class_name InventoryController

@onready var context_menu: PopupMenu = %ContextMenu

var item_slots_count: int = 15
var inventory_slot_prefab: PackedScene = load("res://player/inventory/InventorySlot.tscn")
@onready var inventory_grid: GridContainer = %GridContainer
var inventory_slots: Array[InventorySlot] = []
var inventory_full: bool = false

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

func pickup_item(item_data: ItemData) -> void:
	for slot in inventory_slots:
		if not slot.slot_filled:
			slot.fill_slot(item_data)
			inventory_full = not has_free_slot()
			return
	inventory_full = true

func _on_item_swapped_on_slot(from_slot_id: int, to_slot_id: int) -> void:
	var to_slot_item: ItemData = inventory_slots[to_slot_id].slot_data
	var from_slot_item: ItemData = inventory_slots[from_slot_id].slot_data
	inventory_slots[to_slot_id].fill_slot(from_slot_item)
	inventory_slots[from_slot_id].fill_slot(to_slot_item)
	

func _on_item_doubled_clicked(slot_id: int) -> void:
	var slot: InventorySlot = inventory_slots[slot_id]
	if slot.slot_data == null:
		return
	
	match _get_item_action_type(slot.slot_data):
		ActionData.ActionType.CONSUMABLE:
			print("use item")
		ActionData.ActionType.EQUIPPABLE:
			print("equip item")
		ActionData.ActionType.INSPECTABLE:
			print("read note")

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
			context_menu.add_item("Equip", 0)
			context_menu.add_item("Drop", 1)
		ActionData.ActionType.INSPECTABLE:
			context_menu.add_item("Read", 0)
			context_menu.add_item("Discard", 1)

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
					print("use item")
				1:
					print("drop item")
		ActionData.ActionType.EQUIPPABLE:
			match id:
				0:
					print("equip item")
				1:
					print("drop item")
		ActionData.ActionType.INSPECTABLE:
			match id:
				0:
					print("read note")
				1:
					print("discard note")

func _get_item_action_type(item_data: ItemData) -> ActionData.ActionType:
	if not item_data or not item_data.item_model_prefab == null:
		return ActionData.ActionType.INVALID
	
	return item_data.action_data.action_type
