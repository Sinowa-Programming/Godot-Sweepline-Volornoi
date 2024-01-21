@tool
extends Node2D
## Volornoi Diagram.
## The variables size and pointlist are nessasary for the generation,
## while the variable color_map is used to maintain color/id consistancy when
## regenerating. It renders the diagram image through a simple outline shader, that
## is drawn on a rect.



# nessasary data - you will need each section for generation
@export var size := [1152,648]		# can't be less than 1
@export var point_list = []
@export var color_map := {}			# maps colors to cell ids | Format: {color : [id, pos, polygon]}
@export var graph : Dictionary		# in the format { starting : [destination] }. It is set when generating the diagram and is used to create the Astar graph.
var id_num : int = 0


# used for generation/storage
var img_path


# optional data
@export var lookup_diagram : Image	# is used for finding the cell at the position. Like in paradox games
@export var generate_astar := true
@export var render := true
var astar : AStar2D # is set using the graph


func _ready():
	if generate_astar and graph.size() > 1:
		aStarSetup(graph, color_map)


func dataAtPos(mouse_pos : Vector2) -> Array:	# returns the cell id and centerat the clicked position
	var color_code = lookup_diagram.get_pixel(mouse_pos.x, mouse_pos.y)
	color_code = [color_code.r8, color_code.g8, color_code.b8]	# turn into rgb array as the base float format is inconsistant
	if color_code == [0,0,0]:
		return [-1]
	return color_map[color_code]


func _draw():
	# the volornoi diagram needs a texture/square to render the diagram on
	if render:
		draw_rect(Rect2(0.0, 0.0, size[0], size[1]), Color(1.0, 1.0, 1.0, 0.1))


'''
aStarSetup:
	- graph is the triangular graph generated by the volornoi diagram
	- colorMap is the defnition map that connects each color to an id and position. I will use it to determine each cell's id and position
'''

func aStarSetup(graph: Dictionary, colorMap : Dictionary) -> void:
	astar = AStar2D.new()
	#astar.reserve_space(len(graph))
	var idTable = {}	# contains each site with an id attached for fast lookup of ids when connecting the points
	# add the points to the aStarNode
	for color in colorMap:
		var siteId = colorMap[color][0]
		var siteLoc = colorMap[color][1]
		idTable[siteLoc] = siteId
		astar.add_point(siteId, siteLoc)
	
	# connect the points
	for site_loc in graph:
		var destinations = graph[site_loc]
		for destination in destinations:
			astar.connect_points(idTable[site_loc], idTable[destination], true)	# we are connecting everything to each other
