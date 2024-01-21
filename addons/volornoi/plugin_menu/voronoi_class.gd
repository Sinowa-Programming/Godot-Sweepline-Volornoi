extends Resource
class_name VoronoiSweepline

var voronoi
var pointlist : Array[Vector2]
var size : Array
var cells : Dictionary

func _init() -> void:
	voronoi =  load("res://addons/volornoi/sweepline.gd").new()

# Sizebox is in [left wall, right wall, floor, ceiling]
func generate( point_list : Array[Vector2], sizebox : Array) -> void:
	pointlist = point_list
	size = sizebox
	
	voronoi.execute(pointlist, size)
	cells = voronoi.cells


# Lloyd's relaxation algorithm.
func relax() -> void:
	var chunk_num : int = OS.get_processor_count()
	var new_pnt_lst : Array[Vector2] = []
	new_pnt_lst.resize( voronoi.cells.size() ) 
	
	# Make sure there are enough seed points to do multi-threading for finding the centroids
	if chunk_num < cells.size():
		var chunks : Array[Array]
		var chunksize : int = floor(voronoi.cells.size() / float(chunk_num))
		chunks.resize( chunk_num )
		
		var chunk_idx : int = 0	# Assigns the chunk that each cell goes to
		var j : int = 0
		
		for i : int in range(chunk_num-1):
			chunks[i].resize( chunksize )
		
		chunks[chunk_num - 1].resize( (voronoi.cells.size() - ((chunk_num-1) * chunksize)))
		for cell_name : Vector2 in voronoi.cells:
			chunks[chunk_idx][j] = voronoi.cells[cell_name][0]
			j += 1
			if j >= chunksize and (chunk_idx+1) < chunk_num:
				j = 0
				chunk_idx += 1
		
		# Multithread it
		var thread_lst : Array[Thread]
		thread_lst.resize(chunk_num)
		for i : int in range(chunk_num):
			thread_lst[i] = Thread.new()
			#thread_lst[i].set_thread_safety_checks_enabled( false )
			thread_lst[i].start( process_cell_chunk.bind(chunks[i], i * chunksize, new_pnt_lst) )
		
		for thread : Thread in thread_lst:
			thread.wait_to_finish()
	else:
		var i : int = 0
		for cell_name : Vector2 in voronoi.cells:
			new_pnt_lst[i] = calc_centroid(voronoi.cells[cell_name][0])
			i += 1
	
	generate(new_pnt_lst, voronoi.size)	# Only the points are changing


func process_cell_chunk( chunk : Array, start_idx : int, output_lst : Array[Vector2]) -> void:
	for cell : Array in chunk:
		output_lst[start_idx] = calc_centroid(cell)
		start_idx += 1


func calc_centroid(pointlist : Array) -> Vector2:
	var centroid : Vector2 = Vector2.ZERO
	for pnt : Vector2 in pointlist:
		centroid += pnt
	
	return centroid / pointlist.size()
