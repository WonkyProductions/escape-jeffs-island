extends Node

var files =3
var player_pos = Vector2.ZERO
var cause = "JEFFREY"

func _ready():
	pass

func _process(delta):
	files = max(0, files)

func reset():
	files = 3
	player_pos = Vector2.ZERO
	cause = "JEFFREY"
