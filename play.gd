extends Button

func _ready():
	pressed.connect(_on_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_pressed():
	Global.reset()
	var color_rect = $"../col"
	color_rect.show()
	color_rect.fade = true
	await color_rect.fade_complete
	get_tree().change_scene_to_file("res://loading.tscn")
	
# ColorRect script
