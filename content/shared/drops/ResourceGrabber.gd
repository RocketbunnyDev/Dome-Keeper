extends Area2D

signal grabbed_resource

export (String, "", "iron", "water", "sand") var dropType: = ""

var spent: = false

func dropTarget()->Vector2:
	return global_position

func arrived(gadget):
	gadget.shred()
	emit_signal("grabbed_resource")

func _on_ResourceGrabber_area_entered(area):
	if spent:
		return 
	
	var drop = area.getDeliverableDrop(dropType)
	if drop:
		drop.floatToDropTarget(self)
		spent = true
