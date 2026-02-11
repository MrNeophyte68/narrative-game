extends Node3D

@export var timer: float = 0.0

func _process(delta: float) -> void:
	if timer > 0.0:
		timer -= delta
