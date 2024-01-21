@tool
extends Node
## Volornoi Node autoload using the sweepline algorithm
## Returns a dictionary in the format 	{site : [[ [x1, y1], [x2, y2] ], [neighbor site1, neighbor site2]] }
## Return type: 						{Vector2 : [[ Array, Array ], [ Array, Array ]] }


var volornoi_script	# The volornoi script
var poisson_script	# The poisson algorithm port

func _ready():
	var volornoi_file = preload("res://addons/volornoi/plugin_menu/sweepline.gd")
	volornoi_script = volornoi_file.new()
	
	var poisson_file = preload("res://addons/volornoi/poisson/poisson.gd")
	poisson_script = poisson_file.new()

func volornoi(point_list : Array, size : Array) -> Dictionary:
	if not point_list.is_empty():
		return volornoi_script.execute(point_list, size)
	else:
		push_error("you need points!")
		return {}

func poisson(radius : float, tries : int, size : Array) -> Array:
	return poisson_script.execute(radius, tries, size)
