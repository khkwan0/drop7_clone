extends Node2D

var lanes = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	var lane_width = get_viewport().get_visible_rect().size.x/lanes
	for i in lanes:
		print("draw")
		draw_line(Vector2(i * lane_width, 1), Vector2(i * lane_width, 400), Color.BLACK, 1)
