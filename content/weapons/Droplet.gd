extends RigidBody2D

var p
var stopped: = false

func _ready():
	p = $CPUParticles2D
	remove_child(p)
	get_parent().add_child(p)
	p.position = self.position

func _process(delta):
	if stopped:
		return 
	p.position = self.position
	p.emitting = linear_velocity.length() > 30.0

func kill():
	p.emitting = false
	stopped = true

