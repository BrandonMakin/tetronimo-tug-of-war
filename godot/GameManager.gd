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
var secondsBetweenFalling: float = .2

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
	print(-1 % 3)
#	wrapi

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	fallingTimer += delta
	if fallingTimer >= secondsBetweenFalling:
		_drop_block()
		fallingTimer = 0

func _input(event):
	if event.is_action("rotate_cw"):
		piece.rotate_cw()
	if event.is_action("rotate_ccw"):
		piece.rotate_ccw()

func _update_block_pos() -> void:
	piece.position = pos * block_size + block_topleft_offset

func _drop_block() -> void:
	if _block_can_fall():
		pos.y += 1
		_update_block_pos()

func _block_can_fall() -> bool:
	var bounding_box := piece.current_shape.get_used_rect()
	return pos.y < 20 - bounding_box.size.y
