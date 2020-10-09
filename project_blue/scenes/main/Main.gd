extends Spatial

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("generate"):
		$ProcGen_Old.run_generate(true)
