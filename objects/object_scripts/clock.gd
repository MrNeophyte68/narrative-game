extends StaticBody3D

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var minutes: MeshInstance3D = $minutes
# y degree 0 -> 6h, y degree 180 -> 12h
var starting_rotation: float = 90.0

func _process(delta: float) -> void:
	if player.get_parent().timer:
		var minute = player.get_parent().timer / 60.0
		var rotation = (minute / 5.0) * 30.0
		minutes.rotation_degrees.y = starting_rotation - rotation
