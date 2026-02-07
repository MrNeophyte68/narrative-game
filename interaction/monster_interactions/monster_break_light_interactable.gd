extends Node

@export var lights_to_affect: Array[Node3D]
@export var area_of_effect: Area3D
@export var target_location: Node3D
@export var object_ref: Node3D
var panel_broken: bool = false
@onready var monster: Enemy

func _ready() -> void:
	area_of_effect.connect("body_entered", Callable(self, "near_panel"))
	area_of_effect.connect("body_exited", Callable(self, "far_from_panel"))

func near_panel(body: Node3D) -> void:
	if body.is_in_group("enemy") and not panel_broken:
		body.is_near_light_panel = true
		body.last_panel_position = target_location.global_position
		monster = body

func far_from_panel(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		body.is_near_light_panel = false
		monster = null

func _process(delta: float) -> void:
	if monster:
		if monster.animation_player.current_animation == "break" and not panel_broken:
			panel_broken = true
			await get_tree().create_timer(1.0, false).timeout
			for light in lights_to_affect:
				light.set_lights(false)
