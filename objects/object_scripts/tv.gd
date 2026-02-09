extends Node3D

@onready var code: String
@onready var sub_viewport: SubViewport = %SubViewport
@onready var tvMesh: MeshInstance3D = %tv_mp_1_2
@onready var video_stream_player: VideoStreamPlayer = %VideoStreamPlayer
@onready var symbol: Label3D = %symbol
@onready var video_stream_player_2: VideoStreamPlayer = %VideoStreamPlayer2
var taped_inserted: bool = false
var can_play: bool = false
@export var player: Player
@export var terminal_interface: Node3D
var generate_code: bool = false

func _ready():
	code = generate_random_letters()
	transmit_code_to_terminal(code)
	var viewport_texture = sub_viewport.get_texture()
	
	var material := StandardMaterial3D.new()
	material.shading_mode = material.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport_texture
	
	tvMesh.set_surface_override_material(1, material)

func _process(delta: float) -> void:
	if player == null:
		return

	var ray = player.interaction_raycast

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and taped_inserted:
			if collider.name == "tv" and Input.is_action_just_pressed("primary") and can_play:
				execute()


func generate_random_letters() -> String:
	var letters := "EFGH"
	var result := ""
	
	for i in range(3):
		var index := randi() % letters.length()
		result += letters[index]
		
	return result

func transmit_code_to_terminal(_code: String) -> void:
	if terminal_interface:
		var ic = terminal_interface.find_child("InteractionComponent", true, false)
		for letter in _code:
			ic.correct_code.append(letter.to_upper().unicode_at(0) - "A".unicode_at(0) - 4)

func execute() -> void:
	taped_inserted = true
	can_play = false
	video_stream_player.modulate.a = 1.0
	video_stream_player.play()
	var time := 0.0
	while time < 6.0:
		await get_tree().process_frame
		time += get_process_delta_time()

	video_stream_player.modulate.a = 0.5
	
	for i in code:
		symbol.text = i
		var time_passed := 0.0
		var duration := 2.0
		while time_passed < duration:
			await get_tree().process_frame
			time_passed += get_process_delta_time()

	symbol.text = ""

	# Optionally play second video
	if randf() > 0.95:
		video_stream_player_2.modulate.a = 0.5
		video_stream_player_2.play()
		var time_passed := 0.0
		while time_passed < 3.0:
			await get_tree().process_frame
			time_passed += get_process_delta_time()
		video_stream_player_2.stop()
		video_stream_player_2.modulate.a = 0.0

	video_stream_player.stop()
	video_stream_player.modulate.a = 0.0
	if not video_stream_player.is_playing():
		can_play = true
