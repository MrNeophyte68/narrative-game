extends Camera3D
class_name CameraShake

@export var noise: FastNoiseLite

@onready var initial_rotation: Vector3 = rotation_degrees

var trauma: float = 0.0
var trauma_reduction_rate: float = 1.0
var time: float = 0.0

var noise_speed: float = 50.0
var max_x: float = 10.0
var max_y: float = 10.0
var max_z: float = 5.0

func _process(delta: float) -> void:
	time += delta
	trauma = max(trauma - delta * trauma_reduction_rate, 0.0)

func add_trauma(trauma_amount: float) -> void:
	trauma = clamp(trauma + trauma_amount, 0.0, 1.0)
	rotation_degrees.x = 0.0 + max_x * get_shake_intensity() * get_noise_from_seed(0)
	rotation_degrees.y = 168.3 + max_y * get_shake_intensity() * get_noise_from_seed(1)
	rotation_degrees.z = 0.0 + max_z * get_shake_intensity() * get_noise_from_seed(2)

func get_shake_intensity() -> float:
	return trauma * trauma

func get_noise_from_seed(_seed: int) -> float:
	noise.seed = _seed
	return noise.get_noise_1d(time * noise_speed)
