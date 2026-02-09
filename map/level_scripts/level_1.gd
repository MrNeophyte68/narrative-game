extends Node3D

@onready var vhs_tape_spawn_points: Array[Node] = %VhsTapeLocations.get_children()
@onready var vhs_tape: PackedScene = load("res://objects/items/vhs_tape.tscn")
@onready var objects: Node3D = %Objects

func _ready() -> void:
	randomize()

	if vhs_tape_spawn_points.is_empty():
		push_warning("No VHS tape spawn points found")
		return

	var tape := vhs_tape.instantiate() as Node3D
	var spawn_point = vhs_tape_spawn_points.pick_random()

	tape.global_transform = spawn_point.global_transform
	if spawn_point.name.substr(spawn_point.name.length()-1, 1) == "x":
		tape.rotate_y(90.0)
	add_child(tape)
