extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	text = "MISSION FAILED
[color=gray]CAUSE - " + str(Global.cause)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = "MISSION FAILED
[color=gray]CAUSE - " + str(Global.cause)
