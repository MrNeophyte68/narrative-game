extends Node3D

@export var light_range := 10.0
@export var light_attenuation := 0.8
@export var light_energy := 4.0
@export var volumetric_fog := 3.0

@onready var light: OmniLight3D = %OmniLight3D
@onready var lamp: MeshInstance3D = %ceiling_lamp_1_on
@onready var fake_light: MeshInstance3D = %ceiling_lamp_1_fake_light_2

var flicker_tween: Tween
var is_on: bool = true

func _ready() -> void:
	# Start fully ON
	light.omni_range = light_range
	light.omni_attenuation = light_attenuation
	light.light_energy = light_energy
	light.light_volumetric_fog_energy = volumetric_fog
	lamp.transparency = 0.0

func set_lights(turn_on: bool) -> void:
	# Prevent useless retriggers
	if is_on == turn_on:
		return

	is_on = turn_on

	if flicker_tween:
		flicker_tween.kill()

	flicker_tween = create_tween()
	flicker_tween.set_trans(Tween.TRANS_SINE)
	flicker_tween.set_ease(Tween.EASE_OUT)

	var final_energy := light_energy if turn_on else 0.0
	var final_alpha := 0.0 if turn_on else 1.0
	fake_light.visible = turn_on

	# --- Flicker phase ---
	for i in range(10):
		var flicker_energy := (
			light_energy * randf_range(0.2, 1.2)
			if turn_on
			else randf_range(0.0, light_energy * 0.6)
		)

		var flicker_alpha := randf_range(0.0, 1.0)

		flicker_tween.tween_property(
			light,
			"light_energy",
			flicker_energy,
			randf_range(0.03, 0.07)
		)

		flicker_tween.parallel().tween_property(
			lamp,
			"transparency",
			flicker_alpha,
			randf_range(0.03, 0.07)
		)

	# --- Final settle (definitive state) ---
	flicker_tween.tween_property(light, "light_energy", final_energy, 0.05)
	flicker_tween.parallel().tween_property(lamp, "transparency", final_alpha, 0.05)
