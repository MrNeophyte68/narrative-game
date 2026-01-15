extends Control

@onready var loading_text: RichTextLabel = $RichTextLabel

func _ready():
	GameManager.add_child(self)
	visible = false

func _show_loading(state: bool):
	loading_text.visible = state
