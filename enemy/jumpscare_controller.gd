extends Node

signal jumpscare_finished

@export var jumpscare_camera: Camera3D
@export var jumpscare_duration := 1.2
@onready var ap: AnimationPlayer = %AnimationPlayer
@onready var black_screen: ColorRect = %ColorRect


var is_active := false

func _process(delta: float) -> void:
	jumpscare_camera.add_trauma(0.5)

func start_jumpscare(player: Player):
	if is_active:
		return

	is_active = true
	
	#player.lock_controls(true)
	player.camera_3d.current = false
	player.note_camera.current = false
	jumpscare_camera.current = true
	jumpscare_camera.visible = true
	player.visible = false
	player.sanity_controller.sanity = 0.0
	player.sanity_controller.dead = true
	player.sanity_controller.distortion_material.set_shader_parameter("blur_power", 0.4)
	player.sanity_controller.distortion_material.set_shader_parameter("chaos_shake_intensity", 8)
	
	_play_audio()
	_play_animation()

	await get_tree().create_timer(jumpscare_duration).timeout
	
	end_jumpscare(player)

func end_jumpscare(player: Player):
	#player.lock_controls(false)
	player.sanity_controller.dead = false
	is_active = false
	black_screen.visible = true
	jumpscare_finished.emit()

func _play_audio():
	# scream, sting, etc.
	pass

func _play_animation():
	# enemy animation, camera lunge, etc.
	ap.play("jumpscare")
