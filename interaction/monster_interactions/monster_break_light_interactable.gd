extends Node

@export var lights_to_affect: Array[Node3D]
@export var area_of_effect: Area3D
@export var target_location: Node3D
@export var object_ref: Node3D
var panel_broken: bool = false
@onready var monster: Enemy
@export var player: Player

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

	var ray = player.interaction_raycast
	
	if not panel_broken:
		return

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider:
			if panel_broken and collider.name == "panel":
				player.interaction_controller._focus()
				
			if collider == object_ref and Input.is_action_just_pressed("primary") and panel_broken:
				if player.interaction_controller.item_equipped and player.interaction_controller.equipped_item_ic.item_data.action_data.modifier_name == "capacitor":
					player.interaction_controller.show_item_feedback(player.interaction_controller.equipped_item_ic.item_data.action_data.success_text)
					player.inventory_controller.discard_item(player.inventory_controller.last_equipped_slot_id)
					player.interaction_controller.equipped_item.queue_free()
					player.interaction_controller.item_equipped = false
					panel_broken = false
					for light in lights_to_affect:
						light.set_lights(true)
		else:
			player.interaction_controller._unfocus()
