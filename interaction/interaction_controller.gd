extends Node

@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = %InteractionRaycast
@onready var player_camera: Camera3D = %Camera3D

var current_object: Object
var last_potential_object: Object
var interaction_component: Node

func _process(delta: float) -> void:
	
	#if on the previous frame, we were interacting with an object, let's keep interacting with it
	if current_object:
		if Input.is_action_pressed("primary"):
			if interaction_component:
				interaction_component.interact()
	else: #we weren't interacting with something, let's see if we can
		var potential_object: Object = interaction_raycast.get_collider()
		
		if potential_object and potential_object is Node:
			interaction_component = potential_object.get_node_or_null("InteractionComponent")
			if interaction_component:
				if interaction_component.can_interact == false:
					return
				
				last_potential_object = current_object
				
				if Input.is_action_pressed("primary"):
					current_object = potential_object
					interaction_component.preInteract()
