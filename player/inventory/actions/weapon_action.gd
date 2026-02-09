extends ActionData
class_name WeaponAction

@export var modifier_name: String
var is_upgraded: bool
@export var max_battery_life: float
@export var passive_draining: bool
var is_on: bool = false


func _init() -> void:
	action_type = ActionType.WEAPON
