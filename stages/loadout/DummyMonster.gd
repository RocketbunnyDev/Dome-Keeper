extends Area2D

signal died

var damage = 0
const threshold = 2.0
var currentHealth: = 10

func hit(dmg, stun):
	damage = clamp(damage + dmg, 0, 3.0)
