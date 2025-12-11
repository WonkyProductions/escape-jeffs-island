extends ColorRect

var fade = false
signal fade_complete

func _ready():
	modulate.a = 0

func _process(delta):
	if fade:
		if modulate.a < 1:
			modulate.a += delta * 2
		else:
			modulate.a = 1
			fade = false
			fade_complete.emit()
