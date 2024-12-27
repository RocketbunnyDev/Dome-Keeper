extends "res://systems/camera/CameraBase.gd"

var tween: Tween

var zoomStagePx: float
var target




func init(target):
	zoomStagePx = GameWorld.goalCameraZoom
	cameraRestPositionInDome.y = getCameraRestPosition(zoomStagePx)
	position = cameraRestPositionInDome
	self.target = target
	owner.camera = self
	shake_noise = OpenSimplexNoise.new()
	zoom = Vector2.ONE / zoomStagePx
	tween = Tween.new()
	add_child(tween)
	get_tree().get_root().connect("size_changed", self, "screen_size_changed")
	screen_size_changed()

func screen_size_changed():
	var vprect = get_viewport_rect()
	var sizeDiff = 1080 - vprect.size.y

	GameWorld.aspectRatioYOffset = sizeDiff
	cameraRestPositionInDome.y = getCameraRestPosition(zoomStagePx)

func _process(delta: float)->void :
	var inDome = Data.of("keeper.insidedome")
	if Data.of("monsters.wavepresent") and inDome:
		zoomTo(2)
	elif not Data.of("keeper.insidestation"):
		if inDome:
			zoomTo(GameWorld.goalCameraZoom)
		else:
			zoomTo(Data.of("keeper.zoominmine"))
	
	process_shake(delta)
	
	if GameWorld.won or GameWorld.lost:
		return 
	
	var camDelta: = getCamDelta()
		
	camDelta.y += sign(camDelta.y) * 1.0
	
	camDelta.y = camDelta.y + (max(0, abs(camDelta.y) - 30) / 30.0) * camDelta.y
	var s = target.currentSpeed() * 2.0
	camDelta.y = clamp(camDelta.y, - s, s)
	
	
	camMovement = camDelta

	if camMovement.length() > 5.0:
		position += camMovement * 1 * delta

func getCamDelta()->Vector2:
	var camDelta: = Vector2()
	if Data.of("keeper.insidedome"):
		
		camDelta.x = - position.x
		camDelta.y = cameraRestPositionInDome.y - position.y
	else:
			
			


			
			


			





			
			


















			





			




			


			camDelta.x = target.position.x - position.x
			camDelta.y = target.position.y - position.y
	
	return camDelta

func jump():
	position += getCamDelta()

func zoomTo(pixelStage: float):
	if pixelStage == zoomStagePx:
		return 
	
	self.zoomStagePx = pixelStage
	tween.interpolate_property(self, "cameraRestPositionInDome:y", cameraRestPositionInDome.y, getCameraRestPosition(zoomStagePx), 1.0, Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.interpolate_property(self, "zoom", zoom, Vector2.ONE / zoomStagePx, 2.0, Tween.TRANS_QUAD)
	tween.start()

