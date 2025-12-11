extends WorldEnvironment


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	environment.fog_density = 0.03
	environment.fog_enabled = true
