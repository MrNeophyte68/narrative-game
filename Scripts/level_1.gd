extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var quote = $IntroScreen/Quote
	$child_room/AnimationPlayer2.speed_scale = 2.0
	quote.modulate.a = 0.0
	$IntroScreen/MemoryAudio.play()
	await get_tree().create_timer(5.69, false).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_property(quote, "modulate:a", 1.0, 5.0)
	tween.chain().tween_property(quote, "modulate", Color(0,0,0,0), 5.5)
	await get_tree().create_timer(14, false).timeout
	$child_room/AnimationPlayer2.play("stabbing")
	var tween1 = create_tween().set_parallel(true)
	tween1.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 1.5)
	await get_tree().create_timer(1.0, false).timeout
	$child_room/AnimationPlayer2.speed_scale = 3.5
	await get_tree().create_timer(0.8, false).timeout
	$child_room/AnimationPlayer2.speed_scale = 2.8
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property($IntroScreen/ColorRect, "modulate:a", 1.0, 1.5)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
