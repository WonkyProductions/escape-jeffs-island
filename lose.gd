extends CharacterBody3D

# --- HANDS ---
@onready var left_hand: Node3D = $enemy_mesh/enemy_left_hand_mesh
@onready var right_hand: Node3D = $enemy_mesh/enemy_right_hand_mesh2

# --- Hand Animation Variables ---
var original_left_pos: Vector3 = Vector3.ZERO
var original_right_pos: Vector3 = Vector3.ZERO

var time: float = 0.0

const HAND_START_OFFSET_Y = -0.5


func _prepare_hand_material(hand: Node3D):
	if hand and hand.get_child_count() > 0:
		var mesh_instance = hand.get_child(0)
		if mesh_instance is MeshInstance3D:
			for i in range(mesh_instance.get_surface_override_material_count()):
				var material = mesh_instance.get_surface_override_material(i)
				if material:
					var unique_material = material.duplicate()
					if unique_material is StandardMaterial3D:
						unique_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mesh_instance.set_surface_override_material(i, unique_material)


# --- READY FUNCTION ---

func _ready():
	if left_hand:
		original_left_pos = left_hand.position
		_prepare_hand_material(left_hand)
		left_hand.visible = true

	if right_hand:
		original_right_pos = right_hand.position
		_prepare_hand_material(right_hand)
		right_hand.visible = true


func _process(delta):
	time += delta
	_handle_hands(delta)
	_handle_rotation(delta)


## --- HAND LOGIC ---

func _handle_rotation(delta):
	var rotation_amount = sin(time * 2.0) * deg_to_rad(5.0)
	global_transform.basis = Basis.from_euler(Vector3(0, rotation_amount, 0))


func _handle_hands(delta):
	if left_hand and right_hand:
		var wiggle_amount = 0.1
		var wiggle_speed = 5.0
		var forward_range = 0.1
		
		left_hand.position.x = original_left_pos.x + sin(time * wiggle_speed) * wiggle_amount
		left_hand.position.y = original_left_pos.y + cos(time * wiggle_speed * 0.5) * wiggle_amount * 0.5
		left_hand.position.z = original_left_pos.z + sin(time * 2.0) * forward_range

		right_hand.position.x = original_right_pos.x
		right_hand.position.y = original_right_pos.y + sin(time * wiggle_speed * 0.7) * wiggle_amount * 0.5
		right_hand.position.z = original_right_pos.z + cos(time * wiggle_speed * 1.2) * wiggle_amount + sin(time * 2.0 + 1.5) * forward_range
