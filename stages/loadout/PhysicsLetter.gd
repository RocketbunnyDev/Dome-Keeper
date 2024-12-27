extends RigidBody2D


func init(letter: String, colShape):
	$Label.text = letter
	$CollisionShape2D.shape.radius = colShape.radius
	$CollisionShape2D.shape.height = colShape.height

func _process(delta):
	scale = Vector2.ONE * 0.333333333333333

func hit(dmg, stun):
	pass
