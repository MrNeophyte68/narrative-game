extends Node3D

func _ready() -> void:
	var quote = $IntroScreen/CanvasLayer3/Quote
	$AnimationPlayer2.speed_scale = 2.2
	$AnimationPlayer2.play("camera")
	quote.modulate.a = 0.0
	$IntroScreen/MemoryAudio.play()
	await get_tree().create_timer(5.69, false).timeout
	var tween = create_tween().set_parallel(true)
	tween.tween_property(quote, "modulate:a", 1.0, 6.0)
	tween.chain().tween_property(quote, "modulate", Color(0,0,0,0), 4.0)
	await get_tree().create_timer(14.2, false).timeout
	$AnimationPlayer2.play("stabbing")
	var tween1 = create_tween().set_parallel(true)
	tween1.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 1.5)
	await get_tree().create_timer(1.0, false).timeout
	$AnimationPlayer2.speed_scale = 3.5
	await get_tree().create_timer(0.8, false).timeout
	$AnimationPlayer2.speed_scale = 2.8
	var tween2 = create_tween().set_parallel(true)
	tween2.tween_property($IntroScreen/ColorRect, "modulate:a", 1.0, 1.5)
	await get_tree().create_timer(2.0, false).timeout
	$AnimationPlayer2.play("whiskey_room")
	var tween4 = create_tween()
	tween4.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 1.5)
	tween4.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 0.7)
	tween4.tween_property($IntroScreen/ColorRect, "modulate:a", 1.0, 1.5)
	await get_tree().create_timer(4.0, false).timeout
	$AnimationPlayer2.play("artifact")
	var tween5 = create_tween()
	tween5.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 1.0)
	tween5.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 0.7)
	tween5.tween_property($IntroScreen/ColorRect, "modulate:a", 1.0, 1.0)
	await get_tree().create_timer(3.0, false).timeout
	$AnimationPlayer2.speed_scale = 0.4
	$AnimationPlayer2.play("door")
	var tween6 = create_tween()
	tween6.tween_property($IntroScreen/ColorRect, "modulate:a", 0.0, 1.5)
	await get_tree().create_timer(10.7, false).timeout
	var tween7 = create_tween()
	tween7.tween_property($IntroScreen/ColorRect, "modulate:a", 1.0, 0.0)
	
