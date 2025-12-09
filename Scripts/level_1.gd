extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var quote = $IntroScreen/Quote
	quote.modulate.a = 0.0
	$IntroScreen/MemoryAudio.play()
	await get_tree().create_timer(5.69).timeout
	var tween = create_tween()
	tween.tween_property(quote, "modulate:a", 1.0, 4.94)
	tween.tween_property(quote, "modulate", Color(0,0,0,0), 5.5)
	await get_tree().create_timer(15).timeout
	print("STAB STAB STAB STAB") # switch camera
	$IntroScreen.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
