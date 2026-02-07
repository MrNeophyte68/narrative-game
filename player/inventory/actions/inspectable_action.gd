extends ActionData
class_name InspectableAction

@export var modifier_name: String

func _init() -> void:
	action_type = ActionType.INSPECTABLE
