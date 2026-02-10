extends Node3D

@onready var item_list: Array[RigidBody3D] = [$StaticBody3D/Coin,$StaticBody3D/Pill_Bottle,$StaticBody3D/Battery,$StaticBody3D/Capacitor]

func _ready() -> void:
	item_list.shuffle()
	
	for i in range(3):
		item_list[i].queue_free()
	
	if randf() > 0.9:
		item_list[3].queue_free()
