extends Node3D

@onready var ap: AnimationPlayer = %AnimationPlayer
@onready var barrier: CollisionShape3D = $barrier/CollisionShape3D
@onready var screen: Label3D = %Screen
@export var wallbox: Node
var bootUpText: String = "> booting terminal...


> checking files...
> checking files...
> checking files...


> access granted"

@onready var startuptext: Label3D = %startuptext

func _ready() -> void:
	startuptext.modulate = Color.DARK_GREEN


func execute() -> void:
	screen.visible = false
	ap.play("insert")
	await ap.animation_finished
	for letter in bootUpText:
		startuptext.text += letter
		var time = 0.0
		while time < 0.07:
			await get_tree().process_frame
			time += get_process_delta_time()
	var time = 0.0
	while time < 2.0:
		await get_tree().process_frame
		time += get_process_delta_time()
	startuptext.text = ""
	startuptext.visible = false
	screen.visible = true
	barrier.disabled = true

func code_finished() -> void:
	barrier.disabled = false
	var time = 0.0
	while time < 1.3:
		await get_tree().process_frame
		time += get_process_delta_time()
	screen.text = ""
	wallbox.unlock()
