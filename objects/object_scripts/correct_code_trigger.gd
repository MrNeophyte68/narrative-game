extends Node3D

func unlock() -> void:
	get_parent().code_finished()
