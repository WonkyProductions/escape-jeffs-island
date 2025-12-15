extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not playing:
		if Global.cause == "JEFFREY":
			stream = preload("res://sfx/heavy-breath-male-63980.mp3")
			pitch_scale = .87
			play()
		else:
			stream = preload("res://sfx/gentle-ocean-waves-mix-2018-19693.mp3")
			pitch_scale = 1
			play()
