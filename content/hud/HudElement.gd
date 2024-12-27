extends Control

class_name HudElement

signal request_rebuild

export (Vector2) var size: = Vector2()
export (Vector2) var layoutWeights: = Vector2()
export (int) var layoutPriority: = 0

func _ready():
	Style.init(self)

func init():
	pass
