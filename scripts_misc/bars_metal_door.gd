extends Node3D

var is_on_cooldown: bool = false

@onready var mba: AnimationPlayer = %MetalBarsAnimation
@onready var alarm: AudioStreamPlayer3D = %Alarm
@onready var green_light: AudioStreamPlayer3D = %GreenLight
@onready var gate_close: AudioStreamPlayer3D = %GateClose
@onready var gate_open: AudioStreamPlayer3D = %GateOpen
@export var navMeshOpen: NavigationRegion3D
@export var navMeshClosed: NavigationRegion3D
var enery_level: float = 0.8

@onready var lamps: Array[MeshInstance3D] = [
	%ceiling_lamp_mp_1_on,
	%ceiling_lamp_mp_1_on2
]

var flash_tweens: Array[Tween] = []


func _ready() -> void:
	for lamp in lamps:
		# --- Material setup ---
		var mat := lamp.get_surface_override_material(0) as StandardMaterial3D
		mat = mat.duplicate()
		lamp.set_surface_override_material(0, mat)
		mat.emission_enabled = true
		mat.emission = Color.GREEN

		# --- Light setup ---
		var light := lamp.get_node("OmniLight3D") as OmniLight3D
		light.light_energy = enery_level
		light.light_color = Color.GREEN


func execute() -> void:
	if is_on_cooldown:
		return

	is_on_cooldown = true
	navMeshOpen.enabled = false
	navMeshClosed.enabled = true
	mba.play("close")
	gate_close.play()
	alarm.play()
	flash_red()

	await alarm.finished

	stop_flash()
	mba.play("open")
	gate_open.play()
	navMeshOpen.enabled = true
	navMeshClosed.enabled = false

	await get_tree().create_timer(120.0).timeout
	flash_green_once()
	green_light.play()

	is_on_cooldown = false


func flash_red() -> void:
	stop_flash()

	for lamp in lamps:
		var mat := lamp.get_surface_override_material(0) as StandardMaterial3D
		var light := lamp.get_node("OmniLight3D") as OmniLight3D

		mat.emission_enabled = true
		mat.emission = Color.RED
		light.light_color = Color.RED

		var t := create_tween()
		t.set_loops()

		# ON
		t.tween_property(mat, "emission", Color.RED, 0.4)
		t.parallel().tween_property(light, "light_energy", enery_level, 0.4)

		# OFF
		t.tween_property(mat, "emission", Color.BLACK, 0.5)
		t.parallel().tween_property(light, "light_energy", 0.0, 0.5)

		flash_tweens.append(t)


func flash_green_once() -> void:
	stop_flash()

	for lamp in lamps:
		var mat := lamp.get_surface_override_material(0) as StandardMaterial3D
		var light := lamp.get_node("OmniLight3D") as OmniLight3D

		mat.emission_enabled = true
		mat.emission = Color.GREEN
		light.light_color = Color.GREEN

		var t := create_tween()
		t.tween_property(mat, "emission", Color.GREEN, 0.2)
		t.parallel().tween_property(light, "light_energy", enery_level, 0.2)

		flash_tweens.append(t)


func stop_flash() -> void:
	for t in flash_tweens:
		if t:
			t.kill()
	flash_tweens.clear()

	# Ensure lights are off
	for lamp in lamps:
		var light := lamp.get_node("OmniLight3D") as OmniLight3D
		light.light_energy = enery_level
