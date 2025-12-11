extends Button

func _ready():
	pressed.connect(_on_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	pass

func _on_pressed():
	get_tree().change_scene_to_file("res://loading.tscn")
