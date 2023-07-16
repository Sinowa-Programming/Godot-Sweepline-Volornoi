@tool
extends Node2D

var selected := false
@onready var label = $Sprite2D/Label
signal point_moved
signal point_selected
var pnt = 0	#the point that the node is representing
var activeNode

var radius = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if selected:
		if Input.is_action_just_released("click"):
			selected = false
			emit_signal("point_moved", pnt, position)
		position = lerp(position, activeNode.get_global_mouse_position(), 25*delta)
		position = Vector2(round(position.x), round(position.y))
	label.text = str(position.x) + ", "+ str(position.y)

func point_released():#when the mouse releases the dragged node
	
