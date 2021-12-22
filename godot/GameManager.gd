extends Node2D

enum Piece {I, J, L, O, S, T, Z}

const starting_pos = Vector2(3, -1)

var piece_scenes: Array = [
	preload("res://Pieces/I.tscn"),
	preload("res://Pieces/J.tscn"),
	preload("res://Pieces/L.tscn"),
	preload("res://Pieces/O.tscn"),
	preload("res://Pieces/S.tscn"),
	preload("res://Pieces/T.tscn"),
	preload("res://Pieces/Z.tscn")
]
var bag_index: int = 0
var piece_scene: PackedScene
var falling_piece: Piece
var held_piece: Piece
var shadow_piece: Piece
var falling_timer: float = 0
var shifting_timer: float = 0
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
	falling_timer += delta
	soft_falling = Input.is_action_pressed("soft_drop")
	if (soft_falling and falling_timer >= soft_falling_timing_interval) or (!soft_falling and falling_timer >= falling_timing_interval):
		_drop_piece(falling_piece)
		falling_timer = 0

func _do_shift(delta: float) -> void:
	var shift := int(Input.get_axis("shift_left", "shift_right"))
	if shift:
		shifting_timer += delta
		if shifting_timer >= shifting_time_interval:
			shifting_timer = 0
			var shiftv = Vector2(shift, 0)
			if !_piece_collides_with_wall(shiftv) && !_piece_collides_with_tiles(falling_piece, shiftv):
				falling_piece.position.x += shift
				update_shadow_position()

func _input(event):
	if event.is_action_pressed("rotate_cw") && _piece_can_rotate(falling_piece.Rotation.CLOCKWISE_ONCE):
		falling_piece.rotate_cw()
		shadow_piece.rotate_cw()
		update_shadow_position()
	if event.is_action_pressed("rotate_ccw") && _piece_can_rotate(falling_piece.Rotation.COUNTERCLOCKWISE_ONCE):
		falling_piece.rotate_ccw()
		shadow_piece.rotate_ccw()
		update_shadow_position()
	if event.is_action_pressed("hard_drop"):
		_do_hard_drop()
	if event.is_action_pressed("hold"):
		hold()

func _drop_piece(_piece: Piece) -> void:
	if _piece_can_fall(_piece):
		_piece.position.y += 1

func _piece_can_fall(_piece: Piece) -> bool:
	return !_piece_collides_with_floor(_piece, Vector2(0, 1)) && !_piece_collides_with_tiles(_piece, Vector2(0,1))

func _piece_can_rotate(rotation) -> bool:
	for cell in falling_piece.get_cells_after_rotation(rotation):
		if _tile_collides_with_wall(cell + falling_piece.position):
			return false
		if game_grid.get_cellv(cell + falling_piece.position) != TileMap.INVALID_CELL:
			return false
	return true

func update_shadow_position() -> void:
	shadow_piece.position = falling_piece.position
	for _i in range(20):
		_drop_piece(shadow_piece)

func _do_hard_drop() -> void:
	for _i in range(20):
		_drop_piece(falling_piece)
	_place_piece()

func _place_piece() -> void:
	var cells := falling_piece.get_cells()
	for cell in cells:
		game_grid.set_cellv(cell + falling_piece.position, 0)
	_clear_lines_if_needed()
	_spawn_next_piece()

func _spawn_next_piece() -> void:
	# cycle through bag to get next falling_piece type
	bag_index = bag_index + 1
	if bag_index == 7:
		bag_index = 0
		bag.shuffle()
	
	# create falling_piece
	if falling_piece:
		falling_piece.queue_free()
	falling_piece = _create_piece(bag[bag_index])
	falling_piece.position = starting_pos
	
	# create shadow falling_piece
	_spawn_new_shadow_piece(bag[bag_index])

func _piece_collides_with_tiles(_piece: Piece, offset: Vector2) -> bool:
	for cell in _piece.get_cells():
		if game_grid.get_cellv(cell + _piece.position + offset) != TileMap.INVALID_CELL:
			return true
	return false

func _piece_collides_with_floor(_piece: Piece, offset: Vector2) -> bool:
	var bounding_box := _piece.bounds
	return _piece.position.y + bounding_box.end.y + offset.y > 20

func _piece_collides_with_wall(offset: Vector2) -> bool:
	var bounding_box := falling_piece.bounds
	if falling_piece.position.x + offset.x > 10 - bounding_box.end.x:
		return true
	elif falling_piece.position.x + offset.x + bounding_box.position.x < 0:
		return true
	return false

func _tile_collides_with_wall(point: Vector2) -> bool:
	return point.x < 0 or point.x > 9

func _clear_lines_if_needed() -> void: # This function could be made faster, I think.
	var piece_y := falling_piece.bounds.end.y # y position in current falling_piece, going from bottom to top
	while piece_y > falling_piece.bounds.position.y:
		piece_y -= 1
		var should_clear_line := true
		for board_x in range(10): # x position on board
			var cell_position := Vector2(board_x, piece_y + falling_piece.position.y)
			if game_grid.get_cellv(cell_position) == TileMap.INVALID_CELL:
				should_clear_line = false
				break
		if should_clear_line:
			for board_x in range(10): # x position on board
				for board_y in range(piece_y + falling_piece.position.y, 0, -1): # y position on board
					var above_cell := game_grid.get_cell(board_x, board_y - 1)
					game_grid.set_cell(board_x, board_y, above_cell)
			piece_y += 1

func hold():
	if falling_piece == null:
		return
	
	var temp: = held_piece
	
	# move falling piece to held spot
	held_piece = falling_piece
	held_piece.position = Vector2(-6, -3)
	held_piece._update_current_shape(0)
	
	# (if there is a held piece) move held piece to falling spot
	if temp != null:
		falling_piece = temp
		falling_piece.position = starting_pos
		_spawn_new_shadow_piece(falling_piece.type)
	
	# (if there is not a held piece) spawn a new piece
	else:
		falling_piece = null
		_spawn_next_piece()

# create a piece of no specified use and add it to the game
func _create_piece(type: int) -> Piece:
	var new_piece := piece_scenes[type].instance() as Piece
	new_piece.scale = Vector2.ONE * 1.0/16
	grid_coords.add_child(new_piece)
	return new_piece

func _spawn_new_shadow_piece(type: int) -> void:
	if shadow_piece != null:
		shadow_piece.queue_free()
	shadow_piece = _create_piece(type)
	shadow_piece.modulate = Color(1, 1, 1, .4)
	update_shadow_position()

#func _draw():
#	for cell in falling_piece.get_cells_after_rotation(falling_piece.Rotation.CLOCKWISE_ONCE):
#		var c = Rect2((cell + falling_piece.position)*16, Vector2.ONE*17)
#		draw_rect(c, Color.coral, false, 1)

func _draw():
	for cell in cells_to_draw:
		var c = Rect2((cell)*16, Vector2.ONE*16)
		draw_rect(c, cell_color_to_draw, false, 1)
