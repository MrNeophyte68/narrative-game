extends Node3D

@onready var bars: MeshInstance3D = %bars_metal_2

@onready var cranking_open: AudioStreamPlayer3D = %cranking_open
@onready var finished_opening: AudioStreamPlayer3D = %finished_opening
@onready var gate_closing: AudioStreamPlayer3D = %gate_closing
@onready var finished_closing: AudioStreamPlayer3D = %finished_closing

@export var final_height: float = 2.3
@export var mouse_move_threshold := 5.0
@export var object_ref: Node3D
@export var nav_mesh: NavigationAgent3D

var is_cranking: bool = false
var finished: bool = false
var play_once: bool = false
var previous_height: float = 0.0  # <-- store previous frame height

func _ready():
	play_once = true
	previous_height = 0.0
	if cranking_open.stream:
		cranking_open.stream.loop = true
	if gate_closing.stream:
		gate_closing.stream.loop = true


func _process(delta: float) -> void:
	var mouse_speed: float = Input.get_last_mouse_velocity().length()
	var rotating: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and mouse_speed > mouse_move_threshold
	var ic := object_ref.get_node_or_null("InteractionComponent")
	if ic and not is_cranking and not ic.is_interacting:
		ic.relax_wheel_to_start(delta, 200.0)
	
	if not rotating:
		cranking_open.stop()

func execute(percentage: float) -> void:
	var ic := object_ref.get_node_or_null("InteractionComponent")
	var mouse_speed: float = Input.get_last_mouse_velocity().length()
	var rotating: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and mouse_speed > mouse_move_threshold
	# Current gate height
	var current_height := percentage * final_height
	bars.position.y = current_height

	# Check movement direction
	var height_delta := current_height - previous_height
	if height_delta < 0.0 and not ic.is_interacting:  # gate is moving down
		if not gate_closing.playing:
			gate_closing.play()
	else:
		if gate_closing.playing:
			gate_closing.stop()
			_on_gate_closing_finished()

	previous_height = current_height  # store for next frame

	# Start cranking sound
	if rotating and not is_cranking and percentage > 0.0:
		cranking_open.play()
		is_cranking = true

	if (not rotating or percentage <= 0.0) and is_cranking:
		cranking_open.stop()
		is_cranking = false

	if ic and not ic.is_interacting:
		cranking_open.stop()
		is_cranking = false

	# Finished opening
	if percentage >= 0.99 and not finished:
		finished = true
		cranking_open.stop()
		gate_closing.stop()
		finished_opening.play()
		if ic:
			object_ref.remove_child(ic)

func _on_gate_closing_finished():
	finished_closing.play()
