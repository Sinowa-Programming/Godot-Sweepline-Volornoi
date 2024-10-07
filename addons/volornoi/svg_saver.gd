extends Node

func generateSVGString(voronoi_node : VoronoiSweepline, color_map : Dictionary) -> String:
	var use_color_dict : bool = !color_map.is_empty()
	var svgText := "<svg xmlns='http://www.w3.org/2000/svg' width='"+str(voronoi_node.size[1])+"' height='"+str(voronoi_node.size[3])+"' version='1.1'>\n"
	# Create svg polygons
	if use_color_dict:
		for color_name : Array in color_map:
			var shape := ""
			# Flatten the array to a 1d array
			for point in color_map[color_name]:
				shape += " " +str(point[0]) + "," + str(point[1])
			
			svgText += "<polygon fill='rgb("+str(color_name[0]) +","+ str(color_name[1]) +","+ str(color_name[2])+")' points='"+shape+"'></polygon>\n"
	
	else:
		for cell in voronoi_node.cells:
			var shape := ""
			for point in voronoi_node.cells[cell][0]:
				shape += " " +str(point[0]) + "," + str(point[1])
			
			svgText += "<polygon stroke='rgb(255,255,255)' points='"+shape+"'></polygon>\n"
		
	svgText += "</svg>"
	
	return svgText
