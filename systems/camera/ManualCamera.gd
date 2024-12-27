extends "res://systems/camera/CameraBase.gd"

var tween: Tween

var zoomStagePx: float

func init():
	zoomStagePx = GameWorld.goalCameraZoom
	position = cameraRestPositionInDome
	owner.camera = self
	shake_noise = OpenSimplexNoise.new()
	zoom = Vector2.ONE / zoomStagePx
	tween = Tween.new()
	add_child(tween)
	
func _process(delta: float)->void :
	process_shake(delta)

func zoomTo(pixelStage: float):
	if pixelStage == zoomStagePx:
		return 
