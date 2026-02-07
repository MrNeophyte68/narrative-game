extends Resource
class_name ActionData

enum ActionType {
	INVALID,
	CONSUMABLE,
	EQUIPPABLE,
	INSPECTABLE,
	WEAPON
}

var action_type: ActionType
