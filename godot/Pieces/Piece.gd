extends Node2D
class_name Piece

enum Orientation {
	UNSPECIFIED = -1,
	CLOCKWISE_0 = 0,
	CLOCKWISE_90 = 1,
	CLOCKWISE_180 = 2,
	CLOCKWISE_270 = 4
}

enum Rotation {
	NO_ROTATION = 0,
	CLOCKWISE_ONCE = 1,
	FLIPPED = 2,
	COUNTERCLOCKWISE_ONCE = 3
}

onready var current_shape: TileMap = get_child(0);
onready var _shape_count = get_child_count()

var _current_shape_index: int = Orientation.CLOCKWISE_0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# Rotate clockwise
func rotate_cw():
	_update_current_shape(posmod(_current_shape_index + 1, _shape_count))

# Rotate counterclockwise
func rotate_ccw():
	_update_current_shape(posmod(_current_shape_index - 1, _shape_count))

func _update_current_shape(shape_index: int) -> void:
	current_shape.visible = false
	_current_shape_index = shape_index
	current_shape = get_child(_current_shape_index)
	current_shape.visible = true

func _get_shape(orientation) -> TileMap:
	return get_child(posmod(orientation, _shape_count)) as TileMap

func get_shape_after_rotation(rotation) -> TileMap:
	return _get_shape(get_orientation_from_rotation(rotation))
	
func get_cells(orientation := Orientation.UNSPECIFIED) -> Array:
	if orientation == Orientation.UNSPECIFIED:
		return current_shape.get_used_cells()
	return _get_shape(orientation).get_used_cells()

func get_cells_after_rotation(rotation := Rotation.NO_ROTATION) -> Array:
	return get_cells(get_orientation_from_rotation(rotation))

func get_orientation_from_rotation(rotation):
	return posmod(_current_shape_index + rotation, _shape_count)
