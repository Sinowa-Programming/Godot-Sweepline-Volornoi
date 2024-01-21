@tool
extends EditorPlugin

const VOLORNOI_AUTOLOAD_NAME = "Volornoi"

var eds = get_editor_interface().get_selection()
var plugin_menu
var display_root
signal active_node_changed
signal editor_input


func _enter_tree():
	set_process_input(true)
	add_autoload_singleton(VOLORNOI_AUTOLOAD_NAME, "res://addons/volornoi/autoloads/voronoi_autoload.gd")
	plugin_menu = preload("res://addons/volornoi/plugin_menu/plugin_menu.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, plugin_menu)
	active_node_changed.connect(plugin_menu._on_active_node_changed)
	plugin_menu.main_plugin = self
	editor_input.connect(plugin_menu._on_editor_input)
	add_custom_type("Voronoi", "Node2D", preload("res://addons/volornoi/voronoi_node/voronoi_map.gd"), preload("res://addons/volornoi/voronoi_node/voronoi_icon.png"))
	eds.selection_changed.connect(_on_selection_changed)

func _exit_tree():
	if display_root != null:
		display_root.queue_redraw()	# Clear the display
		display_root.free()
	remove_control_from_docks(plugin_menu)
	plugin_menu.free()
	
	remove_autoload_singleton(VOLORNOI_AUTOLOAD_NAME)
	remove_custom_type("Voronoi")

func _on_selection_changed():
	var selected = eds.get_selected_nodes()
	if not selected.is_empty():
		emit_signal("active_node_changed", selected[0])

func _handles(object):
	return true

func _forward_canvas_gui_input(event):
	if plugin_menu.edit_mode:
		
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mpos = plugin_menu.active_node.get_global_mouse_position()
			if display_root.check_for_selection(mpos) == false:
				emit_signal("editor_input", mpos)
			return true	# Handle the click (stop the rest of the editor from responding)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			if display_root.check_for_removal(plugin_menu.active_node.get_global_mouse_position()):
				return true
		elif event is InputEventMouseButton and event.pressed == false and event.button_index == MOUSE_BUTTON_LEFT:
			if display_root.point_released(plugin_menu.active_node.get_global_mouse_position()):
				return true
	return false
