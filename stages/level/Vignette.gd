extends ColorRect

var target

var strengthStartY: = - 200.0
var strengthEndY: float

var modulateOnPlayerY: = true

func setTarget(t, fullStrengthAt: = 1100):
	self.target = t
	strengthEndY = fullStrengthAt - strengthStartY

func onGameLost():
	
	target = InputSystem.getCamera()

func _process(delta):
	if not is_instance_valid(target):
		target = null
	if not target:
		return 
	var globalCamPos = InputSystem.getCamera().global_position
	var p1pos: Vector2 = (target.global_position - globalCamPos)
	var y: float
	if modulateOnPlayerY:
		y = target.position.y
	else:
		y = globalCamPos.y
	var lerp_offset: float = max(0, y - strengthStartY) / (strengthEndY - strengthStartY)
	lerp_offset = clamp(lerp_offset, 0, 1)
	
	lerp_offset = ease(lerp_offset, - 4)
	var strength = lerp(10.0, 2.0, lerp_offset)
	var alpha = lerp(0.0, 1.0, lerp_offset)
	material.set_shader_param("p1_center_offset", p1pos)
	material.set_shader_param("zoom", InputSystem.getCamera().zoom)
	material.set_shader_param("strength", strength)
	material.set_shader_param("vignette_alpha", alpha)
