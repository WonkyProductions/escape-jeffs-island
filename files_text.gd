extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Global.files == 1:
		text = "Files Left: [color=red]" + str(Global.files)
	else:
		text = "Files Left: " + str(Global.files)
