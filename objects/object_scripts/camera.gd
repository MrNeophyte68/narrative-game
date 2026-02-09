extends RigidBody3D

@onready var indicator: MeshInstance3D = $Indicator
@onready var ic: Node = $InteractionComponent

func _process(delta: float) -> void:
	if ic.item_data.action_data.max_battery_life > 0:
		indicator.get_surface_override_material(0).emission = Color.WEB_GREEN
	else:
		indicator.get_surface_override_material(0).emission = Color.DARK_RED
