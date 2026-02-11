extends Node3D

@onready var vhs_tape_spawn_points: Array[Node] = %VhsTapeLocations.get_children()
@onready var vhs_tape: PackedScene = load("res://objects/items/vhs_tape.tscn")
@onready var objects: Node3D = %Objects
@export var timer: float = 0.0
@export var enemy: Enemy

#to be removed later
@onready var label: Label = $CanvasLayer/Label
@onready var score: Label = $CanvasLayer/Score

func _ready() -> void:
	enemy.reached_player.connect(show_score)
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

func _process(delta: float) -> void:
	if timer > 0.0:
		timer -= delta
	else:
		label.visible = true

func show_score() -> void:
	await get_tree().create_timer(1.2).timeout
	
	var total_seconds = max(0.0, 1200.0 - timer)

	var minutes := int(total_seconds / 60.0)
	var seconds = total_seconds - (minutes * 60)

	if minutes > 0:
		score.text = "You Survived for %dmin %05.2fs" % [minutes, seconds]
	else:
		score.text = "You Survived for %.2fs" % seconds

	score.visible = true
