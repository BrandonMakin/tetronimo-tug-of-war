extends Node

enum Piece {I, J, L, O, S, T, Z}

const block_size: int = 16
const block_topleft_offset: Vector2 = Vector2(16, 32)

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

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	bag.shuffle()
	
	pieceScene = pieceScenes[bag[bagIndex]]
	bagIndex += 1
	piece = pieceScene.instance() as Node2D
	add_child(piece)
	pos = Vector2(3, 0)
	_update_block_pos()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_do_fall(delta)
	_do_shift(delta)
	
func _do_fall(delta: float) -> void:
	fallingTimer += delta
	soft_falling = Input.is_action_pressed("soft_drop")
	if (soft_falling and fallingTimer >= soft_falling_timing_interval) or (!soft_falling and fallingTimer >= falling_timing_interval):
		_drop_block()
		fallingTimer = 0

func _do_shift(delta: float) -> void:
	var shift := Input.get_axis("shift_left", "shift_right")
	if shift:
		shiftingTimer += delta
		if shiftingTimer >= shifting_time_interval:
			shiftingTimer = 0
			pos.x += shift
			_update_block_pos()

func _input(event):
	if event.is_action_pressed("rotate_cw"):
		piece.rotate_cw()
	if event.is_action_pressed("rotate_ccw"):
		piece.rotate_ccw()
	if event.is_action_pressed("hard_drop"):
		_do_hard_drop()

func _update_block_pos() -> void:
	piece.position = pos * block_size + block_topleft_offset

func _drop_block() -> void:
	if _block_can_fall():
		pos.y += 1
		_update_block_pos()

func _block_can_fall() -> bool:
	var bounding_box := piece.current_shape.get_used_rect()
	return pos.y < 21 - bounding_box.size.y - bounding_box.position.y

func _do_hard_drop() -> void:
	for i in range(20):
		_drop_block()
