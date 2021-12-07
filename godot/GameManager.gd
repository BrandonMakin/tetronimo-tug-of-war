extends Node2D

enum Piece {I, J, L, O, S, T, Z}

#const starting_pos = Vector2(3, -1)
const starting_pos = Vector2(0, 0)

var pieceScenes: Array = [
	preload("res://Pieces/I.tscn"),
	preload("res://Pieces/J.tscn"),
	preload("res://Pieces/L.tscn"),
	preload("res://Pieces/O.tscn"),
	preload("res://Pieces/S.tscn"),
	preload("res://Pieces/T.tscn"),
	preload("res://Pieces/Z.tscn")
]
var bagIndex: int = 0
var pieceScene: PackedScene
var pos: Vector2
var piece: Piece
var fallingTimer: float = 0
var shiftingTimer: float = 0
var falling_timing_interval: float = .4
var soft_falling_timing_interval: float = .1
var shifting_time_interval: float = .08
var soft_falling: bool = false

var cells_to_draw := []
var cell_color_to_draw := Color.coral

onready var bag = range(7)
onready var game_grid: TileMap = $"../Game Grid"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	bag.shuffle()
	
	_spawn_next_piece()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_do_fall(delta)
	_do_shift(delta)
	update()
	
func _do_fall(delta: float) -> void:
	fallingTimer += delta
	soft_falling = Input.is_action_pressed("soft_drop")
	if (soft_falling and fallingTimer >= soft_falling_timing_interval) or (!soft_falling and fallingTimer >= falling_timing_interval):
		_drop_piece()
		fallingTimer = 0

func _do_shift(delta: float) -> void:
	var shift := int(Input.get_axis("shift_left", "shift_right"))
	if shift:
		shiftingTimer += delta
		if shiftingTimer >= shifting_time_interval:
			shiftingTimer = 0
			var shiftv = Vector2(shift, 0)
			if !_piece_collides_with_wall(shiftv) && !_piece_collides_with_tiles(shiftv):
				pos.x += shift
				_update_piece_pos()

func _input(event):
	if event.is_action_pressed("rotate_cw") && _piece_can_rotate(piece.Rotation.CLOCKWISE_ONCE):
		piece.rotate_cw()
	if event.is_action_pressed("rotate_ccw") && _piece_can_rotate(piece.Rotation.COUNTERCLOCKWISE_ONCE):
		piece.rotate_ccw()
	if event.is_action_pressed("hard_drop"):
		_do_hard_drop()
	if event is InputEventKey and event.scancode == KEY_Z:
		print(piece.bounds)

func _update_piece_pos() -> void:
	piece.position = pos

func _drop_piece() -> void:
	if _piece_can_fall():
		pos.y += 1
		_update_piece_pos()

func _piece_can_fall() -> bool:
	return !_piece_collides_with_floor(Vector2(0, 1)) && !_piece_collides_with_tiles(Vector2(0,1))

func _piece_can_rotate(rotation) -> bool:
	for cell in piece.get_cells_after_rotation(rotation):
		if _tile_collides_with_wall(cell + pos):
			return false
		if game_grid.get_cellv(cell + pos) != TileMap.INVALID_CELL:
			return false
	return true

func _do_hard_drop() -> void:
	for _i in range(20):
		_drop_piece()
	_place_piece()

func _place_piece() -> void:
	var cells := piece.get_cells()
	for cell in cells:
		print(pos, ", ", cell)
		game_grid.set_cellv(cell + pos, 0)
	_clear_lines_if_needed()
	_spawn_next_piece()

func _spawn_next_piece() -> void:
	if piece:
		piece.queue_free()
	pieceScene = pieceScenes[bag[bagIndex]]
	bagIndex = (bagIndex + 1) % 7
	piece = pieceScene.instance() as Node2D
	piece.scale = Vector2.ONE * 1.0/16
	$"../Falling Piece Coords".add_child(piece)
	pos = starting_pos
	_update_piece_pos()

func _piece_collides_with_tiles(offset: Vector2) -> bool:
	for cell in piece.get_cells():
		if game_grid.get_cellv(cell + pos + offset) != TileMap.INVALID_CELL:
			return true
	return false

func _piece_collides_with_floor(offset: Vector2) -> bool:
	var bounding_box := piece.bounds
	return pos.y + bounding_box.end.y + offset.y > 20

func _piece_collides_with_wall(offset: Vector2) -> bool:
	var bounding_box := piece.bounds
	if pos.x + offset.x > 10 - bounding_box.end.x:
		return true
	elif pos.x + offset.x + bounding_box.position.x < 0:
		return true
	return false

func _tile_collides_with_wall(point: Vector2) -> bool:
	return point.x < 0 or point.x > 9

func _clear_lines_if_needed() -> void: # This function could be made faster, I think.
	for y_within_piece in range(piece.bounds.size.y, 0, -1):
		var should_clear_line := true
		for x in range(10):
			print("hi")
			cells_to_draw = [Vector2(x, y_within_piece + pos.y)]
			cell_color_to_draw = Color.coral
				
			if game_grid.get_cell(x, y_within_piece + pos.y) == TileMap.INVALID_CELL:
				
				cell_color_to_draw = Color.red
				
				should_clear_line = false
				break
			print("bye")
			yield(get_tree().create_timer(.1), "timeout")
		yield(get_tree().create_timer(.1), "timeout")
		if should_clear_line:
			print("owo -> " + str(y_within_piece + pos.y - 1))
			for x in range(10):
				for y in range(y_within_piece + pos.y, 0, -1):
					var above_cell := game_grid.get_cell(x, y-1)
					game_grid.set_cell(x, y, above_cell)
	

#func _draw():
#	for cell in piece.get_cells_after_rotation(piece.Rotation.CLOCKWISE_ONCE):
#		var c = Rect2((cell + pos)*16, Vector2.ONE*17)
#		draw_rect(c, Color.coral, false, 1)

func _draw():
	for cell in cells_to_draw:
		var c = Rect2((cell + pos)*16, Vector2.ONE*16)
		draw_rect(c, cell_color_to_draw, false, 1)
