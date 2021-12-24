extends Node2D
class_name Stockpile

# Declare member variables here.
var index: int = 0
var pieces: Array
var _min_piece_count = 4
var displayed_pieces = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pieces = range(7)
	pieces.shuffle()

func pop() -> int:
	# refill pieces array if needed
	if len(pieces) < _min_piece_count:
			var new_pieces = range(7)
			new_pieces.shuffle()
			pieces += new_pieces
	# display pieces
	display()
	
	# pop and return front of array
	return pieces.pop_front()

func get_current_piece_id() -> int:
	return pieces[0]

func display():
	for piece in displayed_pieces:
		piece.queue_free()
	displayed_pieces = []
	
	for i in range(3):
		var piece = $"../GameManager"._create_piece(pieces[i + 1])
		piece.scale *= 0.5
		piece.position = Vector2(11, -2 + 1.5 * i)
		displayed_pieces.append(piece)
