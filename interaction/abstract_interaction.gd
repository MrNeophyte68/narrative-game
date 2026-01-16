class_name AbstractInteraction
extends Node

## A list of nodes that interacting with this interactable could affect. The nodes in this array should have their own script attached
## that has an "execute" method that you can call using the provided notify_nodes(percentage: float) method.
@export var nodes_to_affect: Array[Node]

## A reference the node that represents this interactable. Most likely the StaticBody3D or PhysicsBody3D node.
var object_ref: Node3D

## True if the player is allowed to interact with this object on this given frame, false otherwise
var can_interact: bool = true

## True if the player is interacting with this object on this frame, false otherwise
var is_interacting: bool = false

## True if the camera should be locked for this type of interaction, false otherwise.
var lock_camera: bool = false


## Runs once, after the node and all its children have entered the scene tree and are ready
func _ready() -> void:
	object_ref = get_parent()

## Runs once, when the player FIRST clicks on an object to interact with
func pre_interact() -> void:
	is_interacting = true
	
## Run every frame while the player is interacting with this object
func interact() -> void: return

## Alternate interaction using secondary button
func aux_interact() -> void: return 
	
## Runs once, when the player LAST interacts with an object
func post_interact() -> void:
	is_interacting = false
	lock_camera = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Iterates over a list of nodes that can be interacted with and executes their respective logic
func notify_nodes(percentage: float) -> void:
	for node in nodes_to_affect:
		if node and node.has_method("execute"):
			node.call("execute", percentage)
