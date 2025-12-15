extends Node

#this is defined on individual objects in the game

enum InteractionType {
	DEFAULT
}

@export var object_ref: Node3D
@export var interaction_type: InteractionType = InteractionType.DEFAULT

var can_interact: bool = true
var is_interacting: bool = false

var player_hand: Marker3D

func _ready() -> void:
	return

#Runs once, when the player first clicks on an object to interact with
func preInteract() -> void:
	is_interacting = true
	match interaction_type:
		InteractionType.DEFAULT:
			player_hand = get_tree().get_root().find_child("Hand", true, false)
		

#Runs every frame, perform some logics on this object
func interact() -> void:
	if not can_interact:
		return
	
	match interaction_type:
		InteractionType.DEFAULT:
			_default_interact()

#Runs once, when the player last interacts with an object
func postInteract() -> void:
	is_interacting = false

func _input(event: InputEvent) -> void:
	return

func _default_interact() -> void:
	var object_current_position: Vector3 = object_ref.global_transform.origin
	var player_hand_position: Vector3 = player_hand.global_transform.origin
	var object_distance: Vector3 = player_hand_position - object_current_position
	
	var rigid_body_3d: RigidBody3D = object_ref as RigidBody3D
	if rigid_body_3d:
		rigid_body_3d.set_linear_velocity((object_distance)*(5/rigid_body_3d.mass ))
