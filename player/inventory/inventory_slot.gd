extends Control
class_name InventorySlot

@onready var icon_slot: TextureRect = $TextureRect
var slot_filled: bool = false
var slot_data: ItemData
var inventory_slot_id: int = -1

signal on_item_swapped(from_slot_id: int, to_slot_id: int)
signal on_item_doubled_clicked(slot_id: int)
signal on_item_right_clicked(slot_id: int)

func fill_slot(item_data: ItemData) -> void:
	slot_data = item_data
	if slot_data != null:
		slot_filled = true
		icon_slot.texture = item_data.item_icon
	else:
		slot_filled = false
		icon_slot.texture = null

func _get_drag_data(at_position: Vector2) -> Variant:
	if slot_filled:
		var preview: TextureRect = TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size = icon_slot.size
		preview.pivot_offset = icon_slot.size / 2.0 + + Vector2(-64, -64)
		preview.texture = icon_slot.texture
		set_drag_preview(preview)
		return inventory_slot_id
	return null

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_INT

func _drop_data(at_position: Vector2, data: Variant) -> void:
	on_item_swapped.emit(data, inventory_slot_id)

func _gui_input(event: InputEvent) -> void:
	if not slot_filled:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			on_item_doubled_clicked.emit(inventory_slot_id)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			on_item_right_clicked.emit(inventory_slot_id)
