extends Node2D
## This is an simple example that generates a set of polygons based on a psudo-randomly
## generated set of points. 


var polygons = []
var sites = []
var graph = {}

func _ready():
	# Settings
	var radius = 25
	var tries = 30
	var size = [1000, 500]
	
	var points = Volornoi.poisson(radius, tries, size)	# Create the points
	
	print("Starting Computation of " + str(len(points)) + " points.")
	var out_dict = Volornoi.volornoi(points, size)	# Create the diagram
	print("Computation done.")
	
	for site_name in out_dict:
		# Add the site
		sites.append(site_name)
		
		# Convert polygon_arr to PackedVector2Array
		var polygon_arr = out_dict[site_name][0]
		var polygon = PackedVector2Array()
		for point in polygon_arr:
			polygon.append( Vector2(point[0], point[1]) )
		polygons.append(polygon)
		
		# Store the nearest neighbors
		graph[site_name] = out_dict[site_name][1]
	
	
	queue_redraw()	#call the _draw() function


func _draw():
	#display the polygons
	for polygon in polygons:
		draw_colored_polygon(polygon, Color(randf(), randf(), randf()))
	
	#draw the connectivity graph
	for start_loc in graph:
		var destinations = graph[start_loc]
		for destination in destinations:
			# The destinations are a point array so you need to convert it to Vector2.
			draw_line(start_loc, Vector2( destination[0], destination[1] ), Color8(255, 0, 0))
	
	#display the sites
	for site in sites:
		draw_circle(site, 3, Color(1.0,1.0,1.0))
	
