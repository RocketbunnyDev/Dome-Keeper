extends Drop

var countDown: = 50.0
var settling: = false
var hatching: = false
var hatched: = false

func _ready():
	Achievements.addIfOpen(self, "PET_FOUND")
	
	Data.listen(self, "inventory.totalrelic")

func propertyChanged(property: String, oldValue, newValue):
	match property:
		
		"inventory.totalrelic":
			if newValue > 0:
				countDown = 0.0


func grow():
	if not hatched or hatching:
		settling = true

func settled():
	$Sprite.play("rooting")
	deactivate()
	mode = RigidBody2D.MODE_STATIC
	set_physics_process(false)
	hatching = true
	settling = false
	position.x = round(position.x)
	position.y = round(position.y)
	z_index = 3
	$CollisionShape2D.disabled = true

func _physics_process(delta):
	._physics_process(delta)
	if settling:
		if linear_velocity.length() < 1.0 and abs(rotation_degrees) < 3.0:
			settled()

func hatch():
	var petId = GameWorld.unlockablePets[randi() % GameWorld.unlockablePets.size()]
	var pet = load("res://content/pets/" + petId + "/" + Data.startCaptialized(petId) + ".tscn").instance()
	$Sprite.play("broken")
	Level.dome.add_child(pet)
	hatching = false
	hatched = true
	GameWorld.lastPetId = petId

func _process(delta):
	if hatching and not hatched:
		countDown -= delta
		
		if countDown <= 0.0 and Level.keeper and Level.keeper.global_position.y > 400:
			hatch()
		
		if GameWorld.devMode and Input.is_action_just_pressed("f4"):
			hatch()

func serialize()->Dictionary:
	var data = .serialize()
	data["countDown"] = countDown
	data["settling"] = settling
	data["hatching"] = hatching
	data["hatched"] = hatched
	return data
	
func deserialize(data: Dictionary):
	.deserialize(data)
	countDown = data["countDown"]
	settling = data["settling"]
	hatching = data["hatching"]
	hatched = data["hatched"]
	
	if hatched:
		$Sprite.play("broken")
	elif hatching:
		$Sprite.play("rooting")
