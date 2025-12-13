extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.cause == "DROWNED":
		position.z = 7.837
		$"../water".show()
	else:
		$"../water".hide()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
