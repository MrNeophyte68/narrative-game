extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var monster_head: Node3D = $monster_head
@onready var player: CharacterBody3D = get_parent().find_child("player", true, false)

func _ready() -> void:
	animation_player.current_animation = "monster_idle"

func _process(delta: float) -> void:
	monster_head.look_at(player.global_transform.origin, Vector3.UP)
