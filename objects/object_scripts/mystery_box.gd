extends Node3D

@export var player: Player

@onready var capacitor: PackedScene = preload("res://objects/items/capacitor.tscn")
@onready var battery: PackedScene = preload("res://objects/items/battery.tscn")
@onready var pill_bottle: PackedScene = preload("res://objects/items/pill_bottle.tscn")

@onready var box_ap: AnimationPlayer = $Box
@onready var item_spin_ap: AnimationPlayer = $ItemSpin
@onready var box_light: OmniLight3D = $OmniLight3D
@onready var item_spinner: Node3D = %item_spinner

var is_open := false
var has_given_item := false
var closing := false
var time_passed := 0.0
var current_instance: Node3D = null

var item_idle_time := 0.0
var item_return_delay := 4.0 # seconds before it starts moving
var item_lerp_speed := 0.1

var target_item_y := 0.0
var item_should_lerp := false


func _process(delta: float) -> void:
	var ray = player.interaction_raycast

	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.name == "box":
			player.interaction_controller._focus()

			if Input.is_action_just_pressed("primary") and not is_open and player.interaction_controller.equipped_item_ic.item_data.action_data.modifier_name == "coin":
				if randf() < 0.15:
					player.interaction_controller.show_item_feedback("the box remained closed")
					player.inventory_controller.discard_item(player.inventory_controller.last_equipped_slot_id)
					player.interaction_controller.equipped_item.queue_free()
					player.interaction_controller.item_equipped = false
				else:
					if player.interaction_controller.item_equipped \
					and player.interaction_controller.equipped_item_ic.item_data.action_data.modifier_name == "coin":
						open_box()
	else:
		player.interaction_controller._unfocus()

	if is_open and not has_given_item:
		time_passed += delta

		if time_passed > 3.3:
			has_given_item = true
			item_spin_ap.play("RESET")
			give_random_item()
		elif time_passed > 2.5:
			item_spin_ap.speed_scale = 0.5
		elif time_passed > 2.0:
			item_spin_ap.speed_scale = 0.7
		elif time_passed > 1.0:
			item_spin_ap.speed_scale = 1.0
		elif time_passed > 0.7:
			item_spin_ap.speed_scale = 1.5
	
	if current_instance and not closing:
		item_idle_time += delta

		if item_idle_time > item_return_delay:
			item_should_lerp = true

		if item_should_lerp:
			var pos := current_instance.global_position
			pos.y = move_toward(pos.y, target_item_y, delta * item_lerp_speed)
			current_instance.global_position = pos
			
			if item_idle_time >= 12.0:
				if closing:
					return

				closing = true
				item_should_lerp = false

				if is_instance_valid(current_instance):
					current_instance.queue_free()
				current_instance = null

				close_box()


func open_box() -> void:
	player.inventory_controller.discard_item(player.inventory_controller.last_equipped_slot_id)
	player.interaction_controller.equipped_item.queue_free()
	player.interaction_controller.item_equipped = false

	is_open = true
	has_given_item = false
	time_passed = 0.0

	box_ap.play("open")
	item_spin_ap.play("spin")
	item_spin_ap.speed_scale = 2.0


func give_random_item() -> void:
	var random := randf()

	if random < 0.5:
		current_instance = pill_bottle.instantiate() as Node3D
	elif random < 0.75:
		current_instance = battery.instantiate() as Node3D
	else:
		current_instance = capacitor.instantiate() as Node3D

	current_instance.position = item_spinner.position
	current_instance.freeze = true

	# Item must emit a `picked_up` signal when collected
	current_instance.get_node_or_null("InteractionComponent").connect("item_collected", Callable(self, "on_item_picked_up"))

	add_child(current_instance)
	item_idle_time = 0.0
	item_should_lerp = false
	target_item_y = item_spinner.global_position.y - 1.0 # sink amount


func on_item_picked_up(item: Node) -> void:
	if closing:
		return

	closing = true
	item_should_lerp = false

	if is_instance_valid(current_instance):
		current_instance.queue_free()
	current_instance = null

	close_box()


func close_box() -> void:
	box_ap.play("close")
	await box_ap.animation_finished

	is_open = false
	has_given_item = false
	time_passed = 0.0
	closing = false
