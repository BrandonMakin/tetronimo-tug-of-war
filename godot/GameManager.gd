extends Node2D

enum Piece {I, J, L, O, S, T, Z}

const block_size: int = 16
const block_topleft_offset: Vector2 = Vector2(16, 32)
const starting_pos = Vector2(3, 0)

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

onready var bag = range(7)
onready var game_grid: TileMap = $"../Dropped Pieces"

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

func _update_piece_pos() -> void:
	piece.position = pos * block_size + block_topleft_offset

func _drop_piece() -> void:
	if _piece_can_fall():
		pos.y += 1
		_update_piece_pos()

func _piece_can_fall() -> bool:
	return !_piece_collides_with_floor(Vector2(0, 1)) && !_piece_collides_with_tiles(Vector2(0,1))

func _piece_can_rotate(rotation) -> bool:
	for cell in piece.get_cells_after_rotation(rotation):
		if _tile_collides_with_wall(cell + pos):
			print("oh?")
			return false
		if game_grid.get_cellv(cell + pos) != TileMap.INVALID_CELL:
			print("woooah")
			return false
	return true

func _do_hard_drop() -> void:
	for _i in range(20):
		_drop_piece()
	_place_piece()

func _place_piece() -> void:
	var cells := piece.get_cells()
	for cell in cells:
		game_grid.set_cellv(cell + pos, 0)
	_spawn_next_piece()

func _spawn_next_piece() -> void:
	if piece:
		piece.queue_free()
	pieceScene = pieceScenes[bag[bagIndex]]
	bagIndex = (bagIndex + 1) % 7
	piece = pieceScene.instance() as Node2D
	add_child(piece)
	pos = starting_pos
	_update_piece_pos()

#func _piece_collides(offset: Vector2) -> bool:
#	return _piece_collides_with_floor(offset) && \
#	_piece_collides_with_right_wall(offset) && \
#	_piece_collides_with_tiles(offset)

func _piece_collides_with_tiles(offset: Vector2) -> bool:
	for cell in piece.get_cells():
		if game_grid.get_cellv(cell + pos + offset) != TileMap.INVALID_CELL:
			return true
	return false

func _piece_collides_with_floor(offset: Vector2) -> bool:
	var bounding_box := piece.current_shape.get_used_rect()
	return pos.y + offset.y > 21 - bounding_box.end.y

func _piece_collides_with_wall(offset: Vector2) -> bool:
	var bounding_box := piece.current_shape.get_used_rect()
	if pos.x + offset.x > 10 - bounding_box.end.x:
		return true
	elif pos.x + offset.x + bounding_box.position.x < 0:
		return true
	return false

func _tile_collides_with_wall(point: Vector2) -> bool:
	return point.x < 0 or point.x > 9

func _draw():
	for cell in piece.get_cells_after_rotation(piece.Rotation.CLOCKWISE_ONCE):
		var c = Rect2((cell + pos)*16 + block_topleft_offset, Vector2.ONE*17)
		draw_rect(c, Color.coral, false, 1)
