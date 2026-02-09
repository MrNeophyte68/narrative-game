extends RigidBody3D

@onready var ic: Node = $InteractionComponent
@onready var primary_sx: AudioStreamPlayer3D = $primary_sx
@onready var life_indicator: MeshInstance3D = $LifeIndicator
@onready var active_indicator: MeshInstance3D = $ActiveIndicator

func _ready() -> void:
	active_indicator.get_surface_override_material(0).emission = Color.DARK_ORANGE
	

func _process(delta: float) -> void:
	if ic.item_data.action_data.is_on and Input.is_action_pressed("secondary"):
		if not primary_sx.playing:
			primary_sx.play()
		active_indicator.get_surface_override_material(0).emission_energy_multiplier = 4.0
	else:
		active_indicator.get_surface_override_material(0).emission_energy_multiplier = 0.01
		primary_sx.stop()
	
	if ic.item_data.action_data.max_battery_life > 0:
		life_indicator.get_surface_override_material(0).emission = Color.WEB_GREEN
	else:
		life_indicator.get_surface_override_material(0).emission = Color.DARK_RED
	
	for player in get_tree().get_nodes_in_group("player"):
		if player.player_state != player.PlayerState.IDLE_STAND:
			ic.item_data.action_data.is_on = false
	
	
	
	
	
