extends Node

const RECOVERY_TIME: float = 6.0 #perk upgrade4
const VISIBILITY_TIME: float = 8.0

var stamina: float = 200.0 #perk upgrade1
var max_stamina: float = 200.0 #perk upgrade1
var drain_rate: float = 15.0 #perk upgrade2
var regen_rate: float = 10.0 #perk upgrade3
var recovery_timer: float = 0.0
var visibility_timer: float = 0.0
var stamina_fade_speed: float = 3.0
var is_visible: bool = false

@onready var player: Player = get_parent()
@onready var stamina_bar: ProgressBar = %Stamina

func _process(delta: float) -> void:
	if player.player_state == player.PlayerState.SPRINTING and stamina > 0.0:
		stamina -= drain_rate * delta
		recovery_timer = RECOVERY_TIME
		visibility_timer = VISIBILITY_TIME
		is_visible = true
	else:
		recovery_timer = max(recovery_timer - delta, 0.0)
		visibility_timer = max(visibility_timer - delta, 0.0)
		if recovery_timer <= 0.0:
			stamina += regen_rate * delta
		if visibility_timer <= 0.0:
			is_visible = false
	
	if is_visible:
		stamina_bar.self_modulate.a = lerp(stamina_bar.self_modulate.a, 1.0, delta * stamina_fade_speed)
	else:
		stamina_bar.self_modulate.a = lerp(stamina_bar.self_modulate.a, 0.0, delta * stamina_fade_speed)

	stamina = clamp(stamina, 0.0, max_stamina)
	stamina_bar.value = stamina
	stamina_bar.max_value = max_stamina
