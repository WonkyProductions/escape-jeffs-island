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


func _on_mouse_entered():
	$"../hover".pitch_scale = 1
	$"../hover".play()


func _on_mouse_exited():
	$"../hover".pitch_scale = 0.9
	$"../hover".play()
	
