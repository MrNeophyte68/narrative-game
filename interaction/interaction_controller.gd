extends Node

@onready var interaction_controller: Node = %InteractionController
@onready var interaction_raycast: RayCast3D = %InteractionRaycast
@onready var player_camera: Camera3D = %Camera3D
@onready var hand: Marker3D = %Hand
@onready var default_reticle: TextureRect = %DefaultReticle
@onready var grab: TextureRect = %Grab
@onready var interactable_check: Area3D = $"../InteractableCheck"
@onready var outline_material: Material = preload("res://materials/outline.tres")
@onready var heavy_marker: Marker3D = %heavy_marker
@onready var note_hand: Marker3D = %NoteHand
@onready var note_overlay: Control = %NoteOverlay
@onready var note_content: RichTextLabel = %NoteContent

var current_object: Object
var last_potential_object: Object
var interaction_component: Node
var note_interaction_component: Node

var is_note_overlay_display: bool = false

#signals
signal change_scene(node: Node3D)

func _ready() -> void:
	interactable_check.body_entered.connect(_on_body_entered)
	interactable_check.body_exited.connect(_on_body_exited)
	#default_reticle.position.x = get_viewport().size.x / 2 - default_reticle.texture.get_size().x / 2
	#default_reticle.position.y = get_viewport().size.y / 2 - default_reticle.texture.get_size().y / 2
	#grab.position.x = get_viewport().size.x / 2 - grab.texture.get_size().x / 2
	#grab.position.y = get_viewport().size.y / 2 - grab.texture.get_size().y / 2
	default_reticle.position.x = 960 - grab.texture.get_size().x / 2
	default_reticle.position.y = 540 - grab.texture.get_size().y / 2
	grab.position.x = 960 - grab.texture.get_size().x / 2
	grab.position.y = 540 - grab.texture.get_size().y / 2
	

func _process(delta: float) -> void:
	if interaction_component and interaction_component.is_interacting:
		default_reticle.visible = false
		grab.visible = false
	
	#if on the previous frame, we were interacting with an object, let's keep interacting with it
	if current_object:
	
		if player_camera.global_transform.origin.distance_to(current_object.global_transform.origin) > 3.0:
			if interaction_component:
				interaction_component.postInteract()
			current_object = null
			_unfocus()
	
		if Input.is_action_just_pressed("secondary"):
			if interaction_component:
				interaction_component.auxInteract()
				current_object = null
				_unfocus()
		elif Input.is_action_pressed("primary"):
			if interaction_component:
				interaction_component.interact()
		else:
			if interaction_component:
				interaction_component.postInteract()
				current_object = null
				_unfocus()
	else: #we weren't interacting with something, let's see if we can
		var potential_object: Object = interaction_raycast.get_collider()
		
		if potential_object and potential_object is Node:
			interaction_component = potential_object.get_node_or_null("InteractionComponent")
			if interaction_component:
				if interaction_component.can_interact == false:
					return
				
				last_potential_object = current_object
				_focus()
				if Input.is_action_just_pressed("primary"):
					current_object = potential_object
					if interaction_component.interaction_type != interaction_component.InteractionType.HEAVY:
						interaction_component.preInteract(hand)
					else:
						interaction_component.preInteract(heavy_marker)
					
					if interaction_component.interaction_type == interaction_component.InteractionType.ITEM:
						interaction_component.connect("item_collected", Callable(self, "_on_item_collected"))
					
					if interaction_component.interaction_type == interaction_component.InteractionType.NOTE:
						interaction_component.connect("note_collected", Callable(self, "_on_note_collected"))
					
					if interaction_component.interaction_type == interaction_component.InteractionType.LOAD_SCENE:
						interaction_component.connect("load_new_scene", Callable(self, "_on_load_new_scene"))
					
					if interaction_component.interaction_type == interaction_component.InteractionType.DOOR:
						interaction_component.set_direction(current_object.to_local(interaction_raycast.get_collision_point()))
			else:
				_unfocus()
		else:
			_unfocus()

func _input(event: InputEvent) -> void:
	if is_note_overlay_display and event.is_action_pressed("primary"):
		note_overlay.visible = false
		is_note_overlay_display = false
		var children = note_hand.get_children()
		for child in children:
			if note_interaction_component.secondary_sx:
				note_interaction_component.secondary_audio_player.stream = note_interaction_component.secondary_sx
				note_interaction_component.secondary_audio_player.play()
				child.visible = false
				await note_interaction_component.secondary_audio_player.finished
			child.queue_free()

func isCameraLocked() -> bool:
	if interaction_component:
		if interaction_component.lock_camera and interaction_component.is_interacting:
			return true
	return false

func _focus() -> void:
	default_reticle.visible = false
	grab.visible = true

func _unfocus() -> void:
	default_reticle.visible = true
	grab.visible = false

func _on_load_new_scene(node: Node3D):
	get_parent().animation_player.play("fade_in")
	await get_parent().animation_player.animation_finished
	emit_signal("change_scene", get_parent())

func _on_item_collected(item: Node):
	#Inventory system
	print("Player Collected: ", item)

func _on_note_collected(note: Node3D) -> void:
	note.get_parent().remove_child(note)
	note_hand.add_child(note)
	note.transform.origin = note_hand.transform.origin
	note.position = Vector3(0.0, 0.0, 0.0)
	note.rotation_degrees = Vector3(90, 10, 0)
	note_overlay.visible = true
	is_note_overlay_display = true
	note_interaction_component = note.get_node_or_null("InteractionComponent")
	note_content.bbcode_enabled = true
	note_content.text = note_interaction_component.content

func _on_body_entered(body: Node3D) -> void:
	if body.name != "Player":
		var int_comp = body.get_node_or_null("InteractionComponent")
		if int_comp and int_comp.interaction_type == int_comp.InteractionType.ITEM:
			var mesh: MeshInstance3D = body.find_child("MeshInstance3D", true, false)
			mesh.material_overlay = outline_material

func _on_body_exited(body: Node3D) -> void:
	if body.name != "Player":
		var mesh: MeshInstance3D = body.find_child("MeshInstance3D", true, false)
		if mesh:
			mesh.material_overlay = null
