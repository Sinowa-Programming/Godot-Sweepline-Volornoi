extends Sprite2D


var nav_pos : int	#used for astar
var nav_path : PackedVector2Array

var selected : bool=false
var parent

func _ready():
	call_deferred("start_at_random_location")

func start_at_random_location() -> void:
	parent = get_parent()
	var data = parent.color_map[parent.color_map.keys()[0]]
	position = data[0]
	
	nav_pos = parent.astar.get_closest_point(data[0])

func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected = true

func _input(event):
	if selected and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_instance_valid(parent):
			nav_path = parent.astar.get_point_path(nav_pos, parent.dataAtPos(parent.get_local_mouse_position())[0] )
			
			# Walk the unit
			for p in nav_path:
				position = p
				nav_pos = parent.dataAtPos(position - parent.position)[0]
				await(get_tree().create_timer(.2).timeout)
			
			nav_pos = parent.dataAtPos(position - parent.position)[0]
		selected = false
