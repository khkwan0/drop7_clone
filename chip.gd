extends RigidBody2D

var _scale = Vector2(1, 1)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _set_scale(__scale):
	_scale = __scale
	$Sprite2D.scale = _scale

	
func _set_collision(__extents):
	$CollisionShape2D.shape.extents = __extents

func explode():
	for i in 5:
		$Sprite2D.scale = Vector2(_scale.x + (i / 5), _scale.y + (i / 5))
		await get_tree().create_timer(0.01).timeout
