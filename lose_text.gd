extends RichTextLabel

var dot_count: int = 0
var timer: float = 0.0
var dot_interval: float = 0.25  # Time between dot changes in seconds

func _ready():
	text = "LOADING"
	modulate.a = 1
func _process(delta):
	pass
