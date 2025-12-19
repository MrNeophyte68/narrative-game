extends Node3D

var starting_rotation: float

@export var final_rotation: float = 90.0

func _ready() -> void:
	starting_rotation = rotation.z
	final_rotation = deg_to_rad(rad_to_deg(starting_rotation)+final_rotation)

func execute(percentage: float) -> void:
	rotation.z = starting_rotation + percentage*(final_rotation-starting_rotation)
