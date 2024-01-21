@tool
extends Node

var grid : Array
var cell_size : float
var size : Array
var cell_width : int
var cell_height : int
var min_radius : float

func execute(_min_radius : float, k : int, img_size : Array) -> Array:
	return process(_min_radius, k, img_size)

#calculate the distance between 2 points
func dist(p1,p2) -> float:
	return float(sqrt(pow(p2[0]-p1[0],2) + pow(p2[1]-p1[1],2)))

func insertPoint(point) -> void:
	grid[floor(point[1]/cell_size)][floor(point[0]/cell_size)] = point

func validatePoint(point) -> bool:
	#check if in bounds
	if (point[0] < 0 or point[0] >= size[0] or point[1] < 0 or point[1] >= size[1]):
		return false
	
	#the grid x and y
	var xindex = floor(point[0]/cell_size)
	var yindex = floor(point[1]/cell_size)
	
	#keep the check area in bounds
	#xmin = max([xindex - 1, 0])
	var xmin = max(xindex - 1, 0)
	#xmax = min([xindex + 2, cell_width])
	var xmax = min(xindex + 2, cell_width)
	#ymin = max([yindex - 1, 0])
	var ymin = max(yindex - 1, 0)
	#ymax = min([yindex + 2, cell_height])
	var ymax = min(yindex + 2, cell_height)
	
	#checking the surrounding 8 cells
	for y in range(ymin, ymax):
		for x in range(xmin, xmax):
			#make sure the grid space is not null. No need to check if 
			if typeof(grid[y][x]) != TYPE_INT:
				if dist(grid[y][x], point) < min_radius:
					return false
	
	return true

#k is the samples before rejection
func process(_min_radius : float, k : int, img_size : Array) -> Array:
	#godot specific
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	#normal code
	size = img_size
	min_radius = _min_radius
	var max_radius = min_radius * 2
	
	const N = 2   #the image is 2d or 2 dimesions
	cell_size = float(min_radius/sqrt(N))
	cell_width = ceil(img_size[0]/cell_size)
	cell_height = ceil(img_size[1]/cell_size)
	
	#create the grid. -1 is the null value
	#grid = [[-1 for i in range(cell_width)] for j in range(cell_height)]
	grid = []
	grid.resize(cell_height)
	for j in range(cell_height):
		var line = []
		line.resize(cell_width)
		line.fill(-1)
		grid[j] = line
		
	
	#contains the final set of points that will be returned
	var pointList := []
	#contains the active points
	var activePointList := []
	
	#random starter point
	var p0 = [rng.randi_range(0,img_size[0]), rng.randi_range(0, img_size[1])]
	insertPoint(p0)
	pointList.append(p0)
	activePointList.append(p0)
	p0 = null
	
	#while there are still active points
	while(activePointList != []):
		var randomIdx = rng.randi_range(0, len(activePointList)-1)
		var chosen_point = activePointList[randomIdx]
		
		var found := false
		for i in range(k):
			#create the point
			var new_radius = rng.randf_range(min_radius, max_radius)
			var theta = rng.randf_range(0, 360)   #the angle of the point relative to the chosen_point. 360 degrees in a circle
			#using the conversion of polar cordinates to rectagular cordinates to get they new point's x and y
			#x = chosen_point[0] + new_radius * cos(radians(theta))
			var x = chosen_point[0] + new_radius * cos(deg_to_rad(theta))
			#y = chosen_point[1] + new_radius * sin(radians(theta))
			var y = chosen_point[1] + new_radius * sin(deg_to_rad(theta))
			var new_point = [x,y]
			
			#check if point is valid | Check the surrounding cells to check that the point is not close to any existing point
			if not validatePoint(new_point):
				continue
			#add to list
			pointList.append(new_point)
			activePointList.append(new_point)
			insertPoint(new_point)
			found = true
			break
		
		
		#no valid point was found so remove it
		if not found:
			activePointList.remove_at(randomIdx)
			#del activePointList[randomIdx]
	
	print("Processing Done. Cleaning Up")
	grid.clear()
	print("Cleaning Complete")
	
	return pointList
