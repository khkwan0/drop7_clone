extends Node2D

var sprite_height = 48
var scale_factor = 1
var win_height = ProjectSettings.get_setting("display/window/size/viewport_height")
@export var drop_speed = 30
# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_height = $Sprite2D.texture.get_height()
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _set_scale(lane_width):
	scale_factor = lane_width / sprite_height
	$Sprite2D.scale = Vector2(scale_factor, scale_factor)
	
func _set_collision(__extents):
	#  $CollisionShape2D.shape.extents = __extents
	pass

func explode():
	for i in 5:
		$Sprite2D.scale = Vector2($Sprite2D.scale.x + (i / 5), $Sprite2D.scale.y + (i / 5))
		await get_tree().create_timer(0.01).timeout
		
func move_up(target_row):
	var target_pixel = (target_row * sprite_height * scale_factor) + win_height / 2 * 0.7
	position.y = target_pixel

# this sets position at the top of the board to drop
func set_initial_position(col, row, lane_width, padding):
	position.x = lane_width * col + lane_width/2 + padding
	position.y = row * lane_width - 6 * lane_width
	
func set_new_chip_position(col, row, lane_width, padding):
	var height = $Sprite2D.texture.get_height()
	position.y = (row * height * scale_factor) + win_height /2 * 0.7
	position.x = lane_width * col + lane_width/2 + padding
	
func drop(target_row):
	var i = 0
	var height = $Sprite2D.texture.get_height()	
	var target_pixel = (target_row * height * scale_factor) + win_height / 2 * 0.7
	#target_pixel -= 250
	#print (position.y)
	while position.y < target_pixel:		
		position.y += drop_speed
		await get_tree().create_timer(0.01).timeout
		i += 1
	position.y = target_pixel
