extends ColorRect

var fade = false
# Called when the node enters the scene tree for the first time.
func _ready():
	modulate.a = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fade:
		if modulate.a != 1:
			modulate.a += delta
		
