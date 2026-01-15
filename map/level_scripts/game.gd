extends Node3D

@onready var player_scene = preload("res://player/player.tscn")
@onready var loading_screen: CanvasLayer = $LoadingScreen

var player: Node3D = null
var current_level: Node3D = null

func _ready():
	if not player:
		player = player_scene.instantiate()
		add_child(player)
		player.interaction_controller.connect("change_scene", Callable(self, "_on_new_scene"))
	
	await load_level("res://map/central_hub.tscn")
	spawn_at("SpawnPoint", 90.0, 0.0)

func load_level(path: String):
	loading_screen.visible = true
	await get_tree().process_frame
	# Free old level
	if current_level:
		current_level.queue_free()
		await current_level.tree_exited
	
	ResourceLoader.load_threaded_request(path)
	var progress = []
	while true:
		var status = ResourceLoader.load_threaded_get_status(path, progress)
		_update_loading_progress(progress[0] if progress.size() > 0 else 0)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		await get_tree().process_frame
	
	var res = ResourceLoader.load_threaded_get(path)
	if res:
		current_level = res.instantiate()
		add_child(current_level)
	await get_tree().create_timer(0.5).timeout
	
	loading_screen.visible = false

func _update_loading_progress(progress_percent: float) -> void:
	var bar = loading_screen.get_node_or_null("ProgressBar") as ProgressBar
	if bar:
		bar.value = progress_percent * 100

func spawn_at(node_name: String, y_rotation: float, x_rotation: float):
	var spawn = current_level.get_node_or_null(node_name)
	if spawn:
		player.global_transform = spawn.global_transform
		player.rotate_y(deg_to_rad(y_rotation))
		player.head.rotate_x(deg_to_rad(x_rotation))
		

func _on_new_scene(node: Node3D) -> void:
	print(current_level.name)
	match current_level.name:
		"CentralHub":
			await load_level("res://map/monster_room.tscn")
			spawn_at("SpawnPoint", 180.0, 0.0)
			player.animation_player.play("fade_out")
		"MonsterRoom":
			await load_level("res://map/central_hub.tscn")
			spawn_at("ReturnFromRoom", 90.0, 0.0)
			player.animation_player.play("fade_out")
