@tool
extends Control
## This file is the main file for the plugin. It handles inputs,
## generation, and save/load operations for the Volornoi node.


@onready var main_operations := $rootContainer/mainOperations
@onready var operations_list := $rootContainer/mainOperations/operationsList
@onready var save_load_operations_list := $rootContainer/mainOperations/operationsList/afterComputationOps
@onready var edit_diagram := $rootContainer/mainOperations/operationsList/EditDiagram
@onready var file_dialog := $FileDialog
@onready var save_json_file_dialog := $savejsonFileDialog
@onready var load_json_file_dialog := $loadFileDialog
@onready var poisson_settings := $rootContainer/poissonSettings
@onready var clear_points_confirmation := $clearPointsConfirmation
@onready var outline_shader = preload("res://addons/volornoi/voronoi_node/simple_outliner.gdshader")
@onready var voronoi_node = preload("res://addons/volornoi/voronoi_node/voronoi.tscn")

# flags
var edit_mode := false
var compute_flag := false
var load_file_flag := false
var save_file_flag := false
var diagram_draw_flag := true
var real_time_flag := true

# internal variables
var active_node = null	# The voronoi node to be operated on
var voronoi	# The voronoi processing c# script instance
#var voronoi_script	# The script that does the heavy calculations
var voronoi_util	# The file that has miscalanois functions that are used in this script 
var display_root = null	# This is a refrence to the display node
var main_plugin	# The main plugin.gd file that manages the whole plugin
var id_table = {}	# A dictionary that contains every point and their color. Is rebuilt every time the active node changes. This is temporary as it will only be used when creating the diagram
var rand_seed = 0	# Used to generate a random color
#var duplicate_min_range = 10	# will not allow a point placed closer than this value to any other point
var file_location	# For saving the svg file
var poisson	# Poisson point generation



func _ready() -> void:
	file_dialog.set_filters(PackedStringArray(["*.svg ; Svg Images",]))	# Filter out non svg files
	var voronoi_script = preload("res://addons/volornoi/plugin_menu/sweepline.gd")
	voronoi = voronoi_script.new()
	var voronoi_util_script = preload("res://addons/volornoi/plugin_menu/voronoi_util.gd")
	voronoi_util = voronoi_util_script.new()
	var poisson_script = preload("res://addons/volornoi/poisson/poisson.gd")
	poisson = poisson_script.new()


func _on_active_node_changed(new_active_node) -> void:
	# If the node has this list of variables then it is an voronoi node
	if "point_list" in new_active_node and "color_map" in new_active_node and "size" in new_active_node and "graph" in new_active_node:
		active_node = new_active_node
		operations_list.visible = true
		if len(active_node.color_map) > 0:
			save_load_operations_list.visible = true
		else:
			save_load_operations_list.visible = false
		build_id_table()
	else:
		operations_list.visible = false
		save_load_operations_list.visible = false
		active_node = null
		edit_mode = false
		edit_diagram.button_pressed = edit_mode
	
	if display_root:
		display_root.queue_redraw()
	else:
		display_root = preload("res://addons/volornoi/display_node/display_root.tscn").instantiate()
		display_root.plugin_menu = self
		get_tree().get_edited_scene_root().get_parent().add_child(display_root)
		display_root.owner = get_tree().get_edited_scene_root().get_parent()
		main_plugin.display_root = display_root
	
	if active_node != null:
		display_root.size_marker = Vector2(active_node.size[0], active_node.size[1])
	
	display_root.queue_redraw()


func _on_new_node_pressed() -> void:
	# Incase the plugin was activated an there was no root scene yet
	if display_root == null:
		display_root = preload("res://addons/volornoi/display_node/display_root.tscn").instantiate()
		display_root.plugin_menu = self
		get_tree().get_edited_scene_root().get_parent().add_child(display_root)
		display_root.owner = get_tree().get_edited_scene_root().get_parent()
		main_plugin.display_root = display_root
	
	active_node = voronoi_node.instantiate()
	active_node.point_list = []	# Its nil for some reason when instantiated
	get_tree().get_edited_scene_root().add_child(active_node)
	active_node.owner = get_tree().get_edited_scene_root()
	active_node.name = "Voronoi"
	active_node.material = ShaderMaterial.new()
	active_node.material.shader = outline_shader
	
	display_root.size_marker = Vector2(active_node.size[0], active_node.size[1])
	display_root.queue_redraw()	# Clear all point incase another voronoi node was previously selected
	build_id_table()	# Will clear the idtable for the new node


func _on_editor_input(mouse_pos) -> void:
	if edit_mode and active_node != null:
		#insert the point to the point list if possible
		insert_point(mouse_pos.x, mouse_pos.y)
		
		if real_time_flag:
			compute()


# The quick variable is for mass insertion. It won't redraw after every insertion
func insert_point(x,y) -> void:
	var pnt = [round(x), round(y)]
	# Makes sure the point is in side of the set size
	if (x < active_node.size[0] and 0 < x) and (y < active_node.size[1] and 0 < y) and not active_node.point_list.has(pnt):
		var rand_gen = RandomNumberGenerator.new()
		rand_gen.seed = rand_seed;
		var color = Color(rand_gen.randf(), rand_gen.randf(), rand_gen.randf())
		while(color in active_node.color_map):
			color = Color(rand_gen.randf(), rand_gen.randf(), rand_gen.randf())
			rand_seed = rand_gen.randi()		# Change the random value so the same number is not regenerated
		
		color = [color.r8, color.g8, color.b8]
		
		active_node.color_map[color] = [active_node.id_num, Vector2(pnt[0],pnt[1]), []]
		id_table[pnt] = color
		active_node.point_list.append(pnt)
		rand_seed = rand_gen.randi()	# Change the random value so the same number is not regenerated
		active_node.id_num += 1
		display_root.queue_redraw()
	else:
		push_warning("Point is outside of max size or is negative! Please change size or move point location and try again!")



func edit_point(pnt, pos : Vector2) -> void:
	var rounded_pos = [round(pos.x), round(pos.y)]
	if pnt == rounded_pos:	# No need to process anything if nothing was moved
		return
	if (pos.x < active_node.size[0] and 0 < pos.x) and (pos.y < active_node.size[1] and 0 < pos.y) and not active_node.point_list.has(rounded_pos):
		active_node.point_list[active_node.point_list.find(pnt,0)] = rounded_pos	# Change the point postion
		# Update the point in the colorMap
		var color = id_table[pnt]
		active_node.color_map[ color ][1] = Vector2(rounded_pos[0],rounded_pos[1])
		# Update the id table's point
		id_table.erase(pnt)
		id_table[rounded_pos] = color
		if real_time_flag:
			compute()
			
		display_root.queue_redraw()
	else:
		if real_time_flag:
			display_root.point_being_dragged = pnt
		push_warning("Point is outside of max size or is negative or is overlapping another point! Please change size or move point location and try again!")


# Remove the point from the active node
func remove_point(pnt) -> void:
	active_node.point_list.erase(pnt)
	active_node.color_map.erase( id_table[pnt] )
	id_table.erase(pnt)
	if real_time_flag:
		compute()


func clear_active_node() -> void:
	active_node.id_num = 0
	active_node.point_list.clear()
	active_node.color_map.clear()
	active_node.graph.clear()
	active_node.lookup_diagram = null
	id_table.clear()
	active_node.queue_redraw()
	display_root.queue_redraw()

func _on_edit_diagram_toggled(button_pressed) -> void:
	edit_mode = button_pressed
	if edit_mode:
		display_root.size_marker = Vector2(active_node.size[0], active_node.size[1])
	display_root.queue_redraw()


func _on_file_dialog_file_selected(path) -> void:
	file_location = path
	generate_color_map()


# Generates the voronoi diagram
# Quick update is the flag that allows for the generation of the graph without the processing of files or nodes
func compute() -> void:
	var graph = {}	# Stores a graph to be used in aStar navigation
	if !active_node.point_list.is_empty():
		var dict = voronoi.execute(active_node.point_list, active_node.size)	# Access the Volornoi autload
		for site in dict:
			var pl = PackedVector2Array()
			var polygonArr = dict[site][0]	# Dict[site][1] contains the cell neighbors
			for point in polygonArr:
				pl.append(Vector2(point[0], point[1]))
			var color = id_table[[site.x, site.y]]
			active_node.color_map[ color ][2] = pl
			graph[site] = dict[site][1]
			
			# Store the graph for Astar generation
			if active_node.generate_astar:
				active_node.graph = graph
		
		save_load_operations_list.visible = true
		display_root.queue_redraw()
	else:
		push_error("you need points!")


# Button that will start the process
func _on_generate_color_map_pressed():
	file_dialog.show()


func generate_color_map():
	# Set the image as the activeNode's lookup diagram
	saveAsSvg()
	
	# If the node has a lookup diagram variable
	if "lookup_diagram" in active_node:
		# Imports the image lossessly to allow for the shader to work correctly
		var image = Image.new()
		image = Image.load_from_file(file_location)
		image.convert(Image.FORMAT_RGBA8)
		active_node.lookup_diagram = image
		active_node.material.set_shader_parameter("lookupDiagram", ImageTexture.create_from_image(image))
		
		active_node.queue_redraw()	# Give a box for the shader to operate on
		display_root.queue_redraw()	# The size box may have changed


# Button for generating polygon nodes
func _on_generate_polygons_pressed():
	compute()
	create_polygons()


# Generate hundreds of polygon nodes using the color_map variable from the active node
func create_polygons() -> void:
	# Create a node to hold all of the polygons
	var polygon_root = Node2D.new()
	polygon_root.name = "polygon_root"
	active_node.add_child(polygon_root)
	
	var color_map = active_node.color_map
	for color in color_map:
		var polygon = active_node.get_node_or_null(str(color_map[color][0]))
		if polygon == null:
			polygon = Polygon2D.new()
			polygon_root.add_child(polygon)
		#print("Color: ", color)
		polygon.color = Color8(color[0], color[1], color[2])	# Color contructor for rgb files
		polygon.polygon = voronoi_util.center_polygon(color_map[color][2], color_map[color][1])
		polygon.name = str(color_map[color][0])	# Id is the name
		var pnt = color_map[color][1]
		polygon.position = Vector2(pnt[0], pnt[1])
		polygon.owner = polygon_root.get_parent()


func saveAsSvg() -> void:
	var svgText := "<svg xmlns='http://www.w3.org/2000/svg' width='"+str(active_node.size[0])+"' height='"+str(active_node.size[1])+"' version='1.1'>\n"
	# Create svg polygons
	for color_name in active_node.color_map:
		var shape := ""
		# Flatten the array to a 1d array
		for point in active_node.color_map[color_name][2]:
			shape += " " +str(point[0]) + "," + str(point[1])
		svgText += "<polygon fill='rgb("+str(color_name[0]) +","+ str(color_name[1]) +","+ str(color_name[2])+")' points='"+shape+"'></polygon>\n"
	svgText += "</svg>"
	
	var svgFile = FileAccess.open(file_location, FileAccess.WRITE)
	svgFile.store_string(svgText)
	svgFile.close()
	active_node.img_path = file_location


func build_id_table() -> void:
	id_table.clear()
	for color_name in active_node.color_map:
		var pnt = active_node.color_map[color_name][1]
		id_table[[pnt.x, pnt.y]] = color_name


# SAVE/LOAD VOLORNOI FILE
func _on_save_diagram_pressed():
	save_json_file_dialog.show()


func _on_load_diagram_pressed():
	load_json_file_dialog.show()


func _on_load_file_dialog_file_selected(path):
	load_file(path)


func _on_savejson_file_dialog_file_selected(path):
	# Can only be reached by a direct call
	save_file(path)


func save_file(file_location : String) -> void:
	var save_dict = {}
	
	# Copy the data to the dictionary
	save_dict["image_path"] = active_node.img_path
	save_dict["size"] = active_node.size
	save_dict["color_map"] = active_node.color_map
	save_dict["point_list"] = active_node.point_list
	save_dict["generate_astar"] = active_node.generate_astar
	if active_node.generate_astar:
		save_dict["graph"] = active_node.graph
	else:
		save_dict["graph"] = {}
	
	# Format the data
	var json_string = JSON.stringify(save_dict)
	
	# Save the data
	var file = FileAccess.open(file_location, FileAccess.WRITE)
	file.store_string(json_string)
	
	# Close the file
	file.close()


func load_file(file_location : String) -> void:
	clear_active_node()	# Make sure the diagram is empty
	
	var json = JSON.new()	# Create a json instance for error handling
	
	var file = FileAccess.open(file_location, FileAccess.READ)
	var json_string = file.get_as_text()
	
	# Retrieve data
	var error = json.parse(json_string)
	
	if error == OK:
		var data_dict = json.data
		active_node.size = data_dict["size"]
		active_node.point_list = data_dict["point_list"]
		active_node.generate_astar = data_dict["generate_astar"]
		active_node.img_path = data_dict["image_path"]
		if data_dict["image_path"] != null:
			var image = Image.new()
			image = Image.load_from_file(data_dict["image_path"])
			image.convert(Image.FORMAT_RGBA8)	# Rasterize the svg
			active_node.lookup_diagram = image
			active_node.material.set_shader_parameter("lookupDiagram", ImageTexture.create_from_image(image))
			push_warning("If the lines of the voronoi diagram don't appear. Just click on the Shader Editor button on the bottom bar.")
		
		# The json isn't fully parsed and the polygon(2 index) and site(1st index) are strings instead of vector2 and packedvector2array
		var color_map = data_dict["color_map"]
		for color_name in color_map:
			var color_key = str_to_var(color_name)
			active_node.color_map[color_key] = [
				color_map[color_name][0],	#the site's id
				str_to_var("Vector2" + color_map[color_name][1]),	# convert the site back to Vector2
				str_to_var("PackedVector2Array" + color_map[color_name][2].replace("(","").replace(")","").replace("[", "(").replace("]", ")")),
			]
			
		if active_node.generate_astar:
			var graph = data_dict["graph"]
			
			# All of the graph's keys were converted to strings as they are vector2s so they have to be transformed back
			for string_vector2 in graph:
				var vector_two = str_to_var("Vector2" + string_vector2)
				active_node.graph[vector_two] = graph[string_vector2]
		
		save_load_operations_list.visible = true
		display_root.queue_redraw()
		active_node.queue_redraw()
	else:
		push_error("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
	
	
	
	build_id_table()


###Poisson disc sampling point placer
func _on_generate_points_pressed():
	main_operations.visible = false
	poisson_settings.visible = true


func _on_poisson_enter_pressed():
	# get the settings
	var radius = poisson_settings.get_node("radius/SpinBox").value
	var tries = poisson_settings.get_node("tries/SpinBox").value	#called k in the algorithm
	
	# generate the points
	var new_points = poisson.execute(radius, tries, active_node.size)
	
	#print("Writing Data to active node...")
	# Add the points to the active node
	for point in new_points:
		# I may report this as a bug later.
		# I have to convert it into a vector2 then pass it in... IDK why but just doing 'insertPoint(point[0], point[1])' does not work.
		var pnt = Vector2(point[0], point[1])
		insert_point(pnt.x, pnt.y)
	
	if real_time_flag:
		compute()
	
	display_root.queue_redraw()	# Display the points
	
	main_operations.visible = true
	poisson_settings.visible = false


# If the 
func _on_poisson_cancel_pressed():
	main_operations.visible = true
	poisson_settings.visible = false


# Clear all points
func _on_clear_points_pressed():
	clear_points_confirmation.show()


# Clear point confirmation popup
func _on_clear_points_confirmation_confirmed():
	clear_active_node()
	display_root.queue_redraw()


# Point Radius changed
func _on_spin_box_value_changed(value):
	display_root.set_radius(int(value))
	display_root.queue_redraw()


# Line Width
func _on_line_spin_box_value_changed(value):
	display_root.set_line_width(value)
	display_root.queue_redraw()


# Shows the nearest neigbor graph
func _on_show__connectivity_graph_toggled(button_pressed):
	display_root.render_graph = button_pressed
	display_root.queue_redraw()


# Changes the setting for the continuous redrawing of the screen when any edit is made
func _on_draw_diagram_toggled(button_pressed):
	real_time_flag = button_pressed
	if real_time_flag:
		compute()
	display_root.queue_redraw()


# A button to allow for a manual reload of the graph
func _on_reload_diagram_pressed():
	compute()
	display_root.queue_redraw()


func _on_show_graph_toggled(button_pressed):
	diagram_draw_flag = button_pressed
	display_root.queue_redraw()
