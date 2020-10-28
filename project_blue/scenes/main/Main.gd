extends Spatial

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
