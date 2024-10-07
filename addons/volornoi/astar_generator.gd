extends Node
'''
This file's purpose is to populate a Astar2D node with the connection
data from the voronoi map. Each point ID is based off of the order that the array of points was
provided to the voronoi class. Every point is bidirectionally connectted and weighted with 1.
'''


func aStarSetup(voronoi_node : VoronoiSweepline, astar : AStar2D) -> AStar2D:
	#astar.reserve_space(len(graph))
	var idTable : Dictionary = {}	# contains each site with an id attached for fast lookup of ids when connecting the points
	# add the points to the aStarNode
	for cell : Vector2 in voronoi_node.cells:
		var idx : int = voronoi_node.pointlist.find(cell)
		astar.add_point(idx, cell)
	
	# connect the points
	for cell : Vector2 in voronoi_node.cells:
		var idx : int = voronoi_node.pointlist.find(cell)
		for neighboring_cell : Vector2 in voronoi_node.cells[cell][1]:
			var nei_idx : int = voronoi_node.pointlist.find(neighboring_cell)
			astar.connect_points(idx, nei_idx)
	
	return astar
