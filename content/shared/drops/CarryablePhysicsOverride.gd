extends Reference

class_name CarryablePhysicsOverride

const IGNORED_VALUE: float = - 99.0

var linear_damp: float = IGNORED_VALUE
var angular_damp: float = IGNORED_VALUE
var gravity_scale: float = IGNORED_VALUE



func apply(body: PhysicsBody2D):
	if linear_damp != IGNORED_VALUE:
		body.linear_damp = linear_damp
	if angular_damp != IGNORED_VALUE:
		body.angular_damp = angular_damp
	if gravity_scale != IGNORED_VALUE:
		body.gravity_scale = gravity_scale

func _to_string()->String:
	return "linear_damp: " + str(linear_damp) + "; angular_damp: " + str(angular_damp) + "; gravity_scale: " + str(gravity_scale)
