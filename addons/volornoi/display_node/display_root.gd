@tool
extends Node2D
## This script displays the size box and points. It also handls dragging and dropping signals 
## sent from plugin_main.gd
## All functions return true if they can handle the event. False if not.


var plugin_menu
var radius = 10	# The point radius
var border = 2	# The point border
var selection_radius = 15
var dragging := false
var point_being_dragged	# Read the name dude/dudet
var size_marker := Vector2()
var size_marker_being_dragged


func set_radius(_radius : int):
	radius = _radius
	border = floor(radius/5)
	selection_radius = radius + 5


func check_for_selection(mouse_pos : Vector2) -> bool:	# Checks if any points are selected if so return true
	# Check if size marker is being selected for dragging
	if size_marker.distance_to(mouse_pos) < selection_radius:
		dragging = true
		size_marker_being_dragged = true
		return true
	
	for pnt in plugin_menu.active_node.point_list:
		if Vector2(pnt[0], pnt[1]).distance_to(mouse_pos) < selection_radius:
			dragging = true
			point_being_dragged = pnt
			return true
	return false


func point_released(mouse_pos : Vector2) -> bool:
	if size_marker_being_dragged:
		dragging = false
		size_marker_being_dragged = false
		return true
	elif dragging:
		plugin_menu.edit_point(point_being_dragged, mouse_pos)
		dragging = false
		return true
	return false


func check_for_removal(mouse_pos : Vector2) -> bool: # Same purpose as last function, but for point removal
	var idx : int = 0
	for pnt in plugin_menu.active_node.point_list:
		if Vector2(pnt[0], pnt[1]).distance_to(mouse_pos) < selection_radius:
			plugin_menu.active_node.point_list.remove_at(idx)
			plugin_menu.remove_point(pnt)
			queue_redraw()
			return true
		idx += 1
	return false


func _process(delta):
	if dragging:
		if size_marker_being_dragged:
			var mpos = plugin_menu.active_node.get_global_mouse_position()
			plugin_menu.active_node.size = [round(mpos.x), round(mpos.y)]
			size_marker = Vector2(round(mpos.x), round(mpos.y))
		queue_redraw()


func _draw():
	if plugin_menu.active_node != null:
		# Draw size box
		var size = plugin_menu.active_node.size
		draw_rect(Rect2(plugin_menu.active_node.position, Vector2(size[0], size[1])), Color(255,0,0), false, 2)
		
		var p_lst = [] + plugin_menu.active_node.point_list
		# Draw points
		if size_marker_being_dragged:
			draw_circle(size_marker, radius, Color("#1897ff"))	# Outer | I am using a hex color code for this line as the rgb wouldn't work without a restart
			draw_circle(size_marker, radius-border, Color("#80e3ff"))	# Inner
		
		elif dragging:
			p_lst.erase(point_being_dragged)
			var pnt := Vector2(plugin_menu.active_node.get_global_mouse_position())
			draw_circle(pnt, radius, Color("#1897ff"))	# Outer | I am using a hex color code for this line as the rgb wouldn't work without a restart
			draw_circle(pnt, radius-border, Color("#80e3ff"))	# Inner
		
		for point in p_lst:
			var pnt := Vector2(point[0], point[1])
			draw_circle(pnt, radius, Color("#2F67FF"))	# Outer | I am using a hex color code for this line as the rgb wouldn't work without a restart
			draw_circle(pnt, radius-border, Color("#FFFFFF"))	# Inner
		
		if plugin_menu.edit_mode:
			if !size_marker_being_dragged:
				draw_circle(size_marker, radius, Color("#2F67FF"))	# Outer | I am using a hex color code for this line as the rgb wouldn't work without a restart
				draw_circle(size_marker, radius-border, Color("#FFFFFF"))	# Inner
