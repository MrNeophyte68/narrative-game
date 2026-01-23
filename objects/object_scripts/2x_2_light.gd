extends Node3D

@export var light_range: float = 10.0
@export var light_attenuation: float = 0.8
@export var light_energy: float = 4.0
@export var volumetric_fog: float = 3.0

@onready var light: OmniLight3D = %OmniLight3D
@onready var lamp: MeshInstance3D = %ceiling_lamp_1_on
var fade_speed: float = 8.0

func _ready() -> void:
	light.omni_range = light_range
	light.omni_attenuation = light_attenuation
	light.light_energy = light_energy
	light.light_volumetric_fog_energy = volumetric_fog

func update_lights(delta: float, is_turned_on: bool) -> void:
	if is_turned_on:
		light.light_energy = lerp(light.light_energy, light_energy, delta*fade_speed)
		lamp.transparency = lerp(lamp.transparency , 0.0, delta*fade_speed)
	else:
		light.light_energy = lerp(light.light_energy, 0.0, delta*fade_speed)
		lamp.transparency = lerp(lamp.transparency , 1.0, delta*fade_speed)
		if lamp.transparency > 0.9:
			lamp.transparency = 1.0
