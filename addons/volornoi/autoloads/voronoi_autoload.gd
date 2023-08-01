@tool
extends Node
## Volornoi Node autoload using the sweepline algorithm
## Returns a dictionary in the format 	{site : [[ [x1, y1], [x2, y2] ], [neighbor site1, neighbor site2]] }
## Return type: 	{Vector2 : [[ Array, Array ], [ Array, Array ]] }


var voronoi_script	# The voronoi script
var poisson_script	# The poisson algorithm port

func _ready():
	var voronoi_file = preload("res://addons/volornoi/plugin_menu/sweepline.gd")
	voronoi_script = voronoi_file.new()
	
	var poisson_file = preload("res://addons/volornoi/poisson/poisson.gd")
	poisson_script = poisson_file.new()


func volornoi(point_list : Array, size : Array) -> Dictionary:
	if not point_list.is_empty():
		return voronoi_script.execute(point_list, size)
	else:
		push_error("you need points!")
		return {}


func poisson(radius : float, tries : int, size : Array) -> Array:
	return poisson_script.execute(radius, tries, size)


func save_as_svg(color_map : Dictionary, size : Array, save_location :  String) -> void:
	var svgText := "<svg xmlns='http://www.w3.org/2000/svg' width='"+str(size[0])+"' height='"+str(size[1])+"' version='1.1'>\n"
	# Create svg polygons
	for color_name in color_map:
		var shape := ""
		# Flatten the array to a 1d array
		for point in color_map[color_name]:
			shape += " " +str(point[0]) + "," + str(point[1])
		svgText += "<polygon fill='rgb("+str(color_name.r8) +","+ str(color_name.g8) +","+ str(color_name.b8)+")' points='"+shape+"'></polygon>\n"
	svgText += "</svg>"
	
	var svgFile = FileAccess.open(save_location, FileAccess.WRITE)
	svgFile.store_string(svgText)
	svgFile.close()
