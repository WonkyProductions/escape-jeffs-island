extends Node

var files = 3
var player_pos = Vector2.ZERO
var cause = "JEFF"

func _ready():
	pass

func _process(delta):
	files = max(0, files)
