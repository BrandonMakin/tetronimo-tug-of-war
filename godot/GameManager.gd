extends Node2D

enum Piece {I, J, L, O, S, T, Z}

const starting_pos = Vector2(3, -1)

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
var piece: Piece
var shadow_piece: Piece
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
onready var grid_coords: Node2D = $"../Falling Piece Coords"

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
		_drop_piece(piece)
		fallingTimer = 0

func _do_shift(delta: float) -> void:
	var shift := int(Input.get_axis("shift_left", "shift_right"))
	if shift:
		shiftingTimer += delta
		if shiftingTimer >= shifting_time_interval:
			shiftingTimer = 0
			var shiftv = Vector2(shift, 0)
			if !_piece_collides_with_wall(shiftv) && !_piece_collides_with_tiles(piece, shiftv):
				piece.position.x += shift
				update_shadow_position()

func _input(event):
	if event.is_action_pressed("rotate_cw") && _piece_can_rotate(piece.Rotation.CLOCKWISE_ONCE):
		piece.rotate_cw()
		shadow_piece.rotate_cw()
		update_shadow_position()
	if event.is_action_pressed("rotate_ccw") && _piece_can_rotate(piece.Rotation.COUNTERCLOCKWISE_ONCE):
		piece.rotate_ccw()
		shadow_piece.rotate_ccw()
		update_shadow_position()
	if event.is_action_pressed("hard_drop"):
		_do_hard_drop()

func _drop_piece(piece: Piece) -> void:
	if _piece_can_fall(piece):
		piece.position.y += 1

func _piece_can_fall(piece: Piece) -> bool:
	return !_piece_collides_with_floor(piece, Vector2(0, 1)) && !_piece_collides_with_tiles(piece, Vector2(0,1))

func _piece_can_rotate(rotation) -> bool:
	for cell in piece.get_cells_after_rotation(rotation):
		if _tile_collides_with_wall(cell + piece.position):
			return false
		if game_grid.get_cellv(cell + piece.position) != TileMap.INVALID_CELL:
			return false
	return true

func update_shadow_position():
	shadow_piece.position = piece.position
	for _i in range(20):
		_drop_piece(shadow_piece)

func _do_hard_drop() -> void:
	for _i in range(20):
		_drop_piece(piece)
	_place_piece()

func _place_piece() -> void:
	var cells := piece.get_cells()
	for cell in cells:
		game_grid.set_cellv(cell + piece.position, 0)
	_clear_lines_if_needed()
	_spawn_next_piece()

func _spawn_next_piece() -> void:
	if piece:
		piece.queue_free()
	pieceScene = pieceScenes[bag[bagIndex]]
	bagIndex = (bagIndex + 1) % 7
	if shadow_piece != null:
		shadow_piece.queue_free()
	piece = pieceScene.instance() as Node2D
	shadow_piece = pieceScene.instance() as Node2D
	piece.scale = Vector2.ONE * 1.0/16
	shadow_piece.scale = Vector2.ONE * 1.0/16
	shadow_piece.modulate = Color(1, 1, 1, .4)
	grid_coords.add_child(piece)
	grid_coords.add_child(shadow_piece)
	piece.position = starting_pos
	update_shadow_position()

func _piece_collides_with_tiles(piece: Piece, offset: Vector2) -> bool:
	for cell in piece.get_cells():
		if game_grid.get_cellv(cell + piece.position + offset) != TileMap.INVALID_CELL:
			return true
	return false

func _piece_collides_with_floor(piece: Piece, offset: Vector2) -> bool:
	var bounding_box := piece.bounds
	return piece.position.y + bounding_box.end.y + offset.y > 20

func _piece_collides_with_wall(offset: Vector2) -> bool:
	var bounding_box := piece.bounds
	if piece.position.x + offset.x > 10 - bounding_box.end.x:
		return true
	elif piece.position.x + offset.x + bounding_box.position.x < 0:
		return true
	return false

func _tile_collides_with_wall(point: Vector2) -> bool:
	return point.x < 0 or point.x > 9

func _clear_lines_if_needed() -> void: # This function could be made faster, I think.
	var piece_y := piece.bounds.end.y # y position in current piece, going from bottom to top
	while piece_y > piece.bounds.position.y:
		piece_y -= 1
		var should_clear_line := true
		for board_x in range(10): # x position on board
			var cell_position := Vector2(board_x, piece_y + piece.position.y)
			if game_grid.get_cellv(cell_position) == TileMap.INVALID_CELL:
				should_clear_line = false
				break
		if should_clear_line:
			for board_x in range(10): # x position on board
				for board_y in range(piece_y + piece.position.y, 0, -1): # y position on board
					var above_cell := game_grid.get_cell(board_x, board_y - 1)
					game_grid.set_cell(board_x, board_y, above_cell)
			piece_y += 1

#func _draw():
#	for cell in piece.get_cells_after_rotation(piece.Rotation.CLOCKWISE_ONCE):
#		var c = Rect2((cell + piece.position)*16, Vector2.ONE*17)
#		draw_rect(c, Color.coral, false, 1)

func _draw():
	for cell in cells_to_draw:
		var c = Rect2((cell)*16, Vector2.ONE*16)
		draw_rect(c, cell_color_to_draw, false, 1)
