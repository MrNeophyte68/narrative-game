extends Control
class_name InventoryController

var item_slots_count: int = 15
var inventory_slot_prefab: PackedScene = load("res://player/inventory/InventorySlot.tscn")
@onready var inventory_grid: GridContainer = %GridContainer
var inventory_slots: Array[InventorySlot] = []
var inventory_full: bool = false

func _ready() -> void:
	for i in item_slots_count:
		var slot = inventory_slot_prefab.instantiate() as InventorySlot
		inventory_grid.add_child(slot)
		
		inventory_slots.append(slot)
