extends Node2D
class_name Piece

onready var current_shape: TileMap = get_child(0);
onready var _shape_count = get_child_count()
var _current_shape_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Rotate clockwise
func rotate_cw():
	_current_shape_index = (_current_shape_index + 1) % _shape_count

# Rotate counterclockwise
func rotate_ccw():
	_current_shape_index = (_current_shape_index - 1) % _shape_count
