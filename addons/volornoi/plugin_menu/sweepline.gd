@tool
extends Node

# site event is type 0
# circle event is type 1
class event:
	var siteIdx : int
	var type : int
	var priority : float
	var site : Array
	
	func _init(_siteIdx : int, _type : int, _priority : float, _site : Array=[]) -> void:
		siteIdx = _siteIdx  #the unique site index for the event
		type = _type
		priority = _priority
		site = _site    #only used for circle events


class PriorityQueue:
	var queue : Array[event]
	var last_event : event
	func _init() -> void:
		queue = []
		last_event = null
	
	func add(event : event) -> void:
		#stop duplicate events
		#if self.last_event:
		if last_event != null:
			if last_event.type == event.type and last_event.siteIdx == event.siteIdx and abs(last_event.priority-event.priority) < .001:
				return
	
		#add event to queue
		if len(queue) > 0 and event.priority < queue[-1].priority:
			for i in range(len(queue)):
				if queue[i].priority > event.priority:
					queue.insert(i, event)
					break
		
		else:
			queue.append(event)
		
		last_event = event
		return
	
	func pop() -> event:  # returns a Event class object
		#return self.queue.pop(0)
		return queue.pop_front()

func execute(_pointLst : Array, _size : Array) -> Dictionary:
	init(_pointLst, _size)
	generate()
	return cells

var size : Array
var pointLst : Array
var cells : Dictionary
func init(_pointLst : Array, _size : Array) -> void:
	
	size = _size
	pointLst = _pointLst
	pointLst.sort_custom(yThenXSort)
	#self.pointLst = sorted(pointLst, key=lambda point: (point[1], point[0]))
	#self.pointLst = pointLst  # sort the point list
	cells = {}
	for point in pointLst:
		cells[tuple(point)] = [[],[]]   #first list contains edges(later polygons). The second contains neigbors

#used as a stand in replacement to the python 'tuple'
func tuple(point : Array) -> Vector2:
	return Vector2(point[0],point[1])

func yThenXSort(p1, p2):
	if p1[1] == p2[1]:
		return p1[0] < p2[0]
	else:
		return p1[1] < p2[1]

#sourceArr is the base array that the DataArr is added to
#DataArr is the iterable that is extended at the index
func extendAtIndex(sourceArr : Array, DataArr: Array, index : int):
	DataArr.reverse()
	for data in DataArr:
		sourceArr.insert(index,data)
	return sourceArr

func nearest_point(point : Array) -> Array:
	var smallestDist = 1000000000
	var pnt = []
	for pt in pointLst:
		var a = pow(point[0] - pt[0], 2) + pow(point[1] - pt[1], 2)
		if a < smallestDist:
			smallestDist = a
			pnt = pt
	return pnt

func orderEdges(cell_name) -> void:
	var cell = cells[cell_name]
	#this function is the final step and I decided it will also handle removing all the selected site and boundary site
	var unique: Array = []
	for item in cell[1]:
		if not unique.has(item):
			unique.append(item)
	
	cell[1] = unique
	#cell[1] = [i for i in cell[1] if i != list(cell_name)]   #cell_name is a tulple as it is hashable
	#cell[1] = [i for i in cell[1] if i != [-1,-1]]     #I don't belive that this line is nessasary as -1,-1 is never inputted into a cell in this implementation

	#self.cells[cell_name][1] = cell[1]     #I believe that they update on their own

	#I will implement corner handling later, is nessasary
	# if self.corner != None:
	# 	self.edges.extend(cell.edgesFromCorner(self.corner, self.edges, size))

	var polygon = []
	var lst = cell[0].duplicate(true)
	polygon.append_array(lst[0])
	#del lst[0]
	lst.remove_at(0)

	for i in range(len(lst)):
		var old_len = len(lst)
		for j in range(len(lst)):
			var edge = lst[j]
			
			if edge[0] == polygon[0]:
				polygon.insert(0, edge[1])
				#del lst[j]
				lst.remove_at(j)
				break
			if edge[1] == polygon[0]:
				polygon.insert(0, edge[0])
				#del lst[j]
				lst.remove_at(j)
				break
			if edge[0] == polygon[-1]:
				polygon.append(edge[1])
				#del lst[j]
				lst.remove_at(j)
				break
			if edge[1] == polygon[-1]:
				polygon.append(edge[0])
				#del lst[j]
				lst.remove_at(j)
				break
		if old_len == len(lst): #no points were removed/ gap in edge list
			#if the point is a root, then the gap is most likely at the floor, so match the y's. I know that this english is bad(yes english is my first language)
			#if list(cell_name) in self.root:
			if [cell_name.x, cell_name.y] in root:
				for j in range(len(lst)):
					var edge = lst[j]
					#find the end point in the polygon that matches the detached edge's x
					if polygon[0][1] == edge[0][1]:
						polygon.insert(0, edge[0])
						polygon.insert(0, edge[1])
						#del lst[j]
						lst.remove_at(j)
						break
					elif polygon[0][1] == edge[1][1]:
						polygon.insert(0, edge[1])
						polygon.insert(0, edge[0])
						#del lst[j]
						lst.remove_at(j)
						break
					elif polygon[-1][1] == edge[0][1]:
						polygon.append_array(edge)
						#del lst[j]
						lst.remove_at(j)
						break
					elif polygon[-1][1] == edge[1][1]:
						edge.reverse()
						polygon.append_array(edge)
						#del lst[j]
						lst.remove_at(j)
						break
			#find the matching point that has the same x as the detached edge
			for j in range(len(lst)):
				var edge = lst[j]
				#find the end point in the polygon that matches the detached edge's x
				if polygon[0][0] == edge[0][0]:
					polygon.insert(0, edge[0])
					polygon.insert(0, edge[1])
					#del lst[j]
					lst.remove_at(j)
					break
				elif polygon[0][0] == edge[1][0]:
					polygon.insert(0, edge[1])
					polygon.insert(0, edge[0])
					#del lst[j]
					lst.remove_at(j)
					break
				elif polygon[-1][0] == edge[0][0]:
					polygon.append_array(edge)
					#del lst[j]
					lst.remove_at(j)
					break
				elif polygon[-1][0] == edge[1][0]:
					edge.reverse()
					polygon.append_array(edge)
					#del lst[j]
					lst.remove_at(j)
					break
	
	
	#remove extra point that points to the polygon starting point
	if polygon[0] == polygon[-1]:
		#del polygon[-1]
		polygon.remove_at(len(polygon)-1)
	
	cell[0] = polygon

#calculate the distance between 2 points
func dist(p1,p2) -> float:
	return sqrt(pow(p2[0]-p1[0],2) + pow(p2[1]-p1[1],2))
	#return math.sqrt(math.pow(p2[0]-p1[0],2) + math.pow(p2[1]-p1[1],2))

func midpoint(p1, p2) -> Array:
	return [(p1[0]+p2[0])/2.0, (p1[1]+p2[1])/2.0]

func dot(v1, v2) -> float:
	var sum = 0
	for i in range(len(v1)):
		sum += v1[i] * v2[i]

	return sum

func diff(p1,p2) -> Array:
	return [p1[0] - p2[0], p1[1] - p2[1]]

func is_point_on_ray(ray, point, ray_dir) -> bool:
	"""
	Checks if a point is on a ray.

	Args:
	ray: The ray in the format [[origin], [direction]].
	point: The point to check.
	ray_dir: The direction of the ray. Sets the sign for the ray length
	Returns:
	True if the point is on the ray, False otherwise.
	"""
	
	#edge case if the start of the ray == the point
	if dist(ray[0], point) < .0001:
		return true
	
	#ray_length = max(size) * 2  #makes sure the raylength exceeds the bounding boxes and passes any exterior ray collisions
	var ray_length = max(size[0], size[1]) * 2.0  #makes sure the raylength exceeds the bounding boxes and passes any exterior ray collisions
	if ray[1][1] == 0:  #if the ray's slope is zero
		if ray[1][0] > 0:   #if the ray is facing rightward
			if ray_dir == "l":
				ray_length *= -1.0
		else:
			if ray_dir == "r":
				ray_length *= -1.0
	elif ray[1][0] > 0:   #if the ray's slope is negative then left == negative and right == positive ray length
		if ray_dir == "l":
			ray_length *= -1.0
	else:   #vise versa if the ray's slope is positive then left == positive and right == negative ray length
		if ray_dir == "r":
			ray_length *= -1.0
	
	var direction = diff(ray[0], [-(ray[1][0] * ray_length), -(ray[1][1] * ray_length)])    #instead of adding them I just subtract and make sure the inputs are negative
	var projection = diff(point, ray[0]) # point - ray_start
	var t = float(dot(projection, direction) / dot(direction, direction))
	#return (0 <= t <= 1)
	return (0 <= t) and (t <= 1)

func rayIntersection(leftEdgeIdx, rightEdgeIdx):
	#check if the rays intersect
	var p1 = beachline[leftEdgeIdx-1]
	var p2 = beachline[leftEdgeIdx+1]  #p2 is p1 for the Right Edge
	var p3 = beachline[rightEdgeIdx+1]
	# lslope = (p2[0]-p1[0])/(p2[1]-p1[1]) * -1  #the ray is perpendictular to edge of p2 and p1 (also called a normal)
	# rslope = (p3[0]-p2[0])/(p3[1]-p2[1]) * -1 #same over here
	
	#llean = self.leans[leftEdgeIdx//2]
	var llean = leans[floor(leftEdgeIdx/2.0)]
	#rlean = self.leans[rightEdgeIdx//2]
	var rlean = leans[floor(rightEdgeIdx/2.0)]
	
	#IDK if this is nessasary, but better safe than sorry
	if llean == "DNE" or rlean == "DNE":
		return
	
	"""
	Finds the intersection between two rays in vector format.
	
	Args:
	ray_a: A tuple of (x0, y0, dx, dy) representing the first ray.
	ray_b: A tuple of (x0, y0, dx, dy) representing the second ray.
	
	Returns:
	A tuple of (x, y) if the rays intersect, or (float('inf'), float('inf')) if they do not intersect.
	"""
	#Calculare the slope of each ray to find their direction
	# slope1 = (p2[0]-p1[0])/(p2[1]-p1[1]) * -1  #the ray is perpendictular to edge of p2 and p1 (also called a normal)
	# slope2 = (p3[0]-p2[0])/(p3[1]-p2[1]) * -1 #same over here
	
	# # check if slopes are equal (rays are parallel)
	# if slope1 == slope2:
	#     return
	
	var ray1 = [beachline[leftEdgeIdx]]
	var ray2 = [beachline[rightEdgeIdx]]
	
	if ray1[0] == [-1,-1]:  #if root
		#ray1[0] = Volornoi.midpoint(p1,p2)
		ray1[0] = midpoint(p1,p2)
	
	if ray2[0] == [-1,-1]:  #if root
		ray2[0] = midpoint(p2,p3)
		#ray2[0] = Volornoi.midpoint(p2,p3)
	
	# ray1.append(Volornoi.midpoint(p1,p2))
	# ray2.append(Volornoi.midpoint(p2,p3))
	# ray_a.extend([-(p2[0]-p1[0]), (p2[1]-p1[1])])
	# ray_b.extend([-(p3[0]-p2[0]), (p3[1]-p2[1])])
	
	#slope 1 x and y
	var s1x = float(p2[1]-p1[1])
	var s1y = float(-(p2[0]-p1[0]))    #has to be negative for the creation of a perpendicular slope
	
	#slope 2 x and y
	var s2x = float(p3[1]-p2[1])
	var s2y = float(-(p3[0]-p2[0]))    #has to be negative for the creation of a perpendicular slope
	if s1y == s2y and s1x == s2x:   #chgeck if the slopes are equal (rays are parallel)
		return
	
	var slope1 : float	#godot specific
	var slope2 : float	#godot specific
	if s1x != 0:
		slope1 = float(s1y/s1x)
	else:
		slope1 = 1000000000.0# the more zeros the more accurate as it is a vertical line
	
	
	if s2x != 0:
		slope2 = float(s2y/s2x)
	else:
		slope2 = 1000000000.0# the more zeros the more accurate as it is a vertical line
	
	ray1.append([s1x, s1y])
	
	ray2.append([s2x, s2y])
	
	# ray1 and ray2 are in the format [origin, direction]
	# origin is a tuple (x, y) representing the starting point of the ray
	# direction is a tuple (dx, dy) representing the direction of the ray
	
	# find intersection point of the two lines that the rays extend from
	var x1 = ray1[0][0]
	var y1 = ray1[0][1]
	var x2 = ray2[0][0]
	var y2 = ray2[0][1]
	var dx1 = ray1[1][0]
	#var dy1 = ray2[0][1]
	var dx2 = ray2[1][0]
	#var dy2 = ray2[1][1]
	
#		x1, y1 = ray1[0]
#		x2, y2 = ray2[0]
#		dx1, dy1 = ray1[1]
#		dx2, dy2 = ray2[1]
	var x : float
	var y : float
	if dx1 == 0:
		x = float(x1)
		y = float(slope2 * (x - x2) + y2)
	elif dx2 == 0:
		x = float(x2)
		y = float(slope1 * (x - x1) + y1)
	else:
		if slope1 == slope2:
			return
		x = float((y2 - y1 + slope1 * x1 - slope2 * x2) / (slope1 - slope2))
		y = float(slope1 * (x - x1) + y1)
	
	
	var point = [x,y]
	##print("point: ", point)
	
	#if a lean is idk then the lean is a root. funcine their lean here.
	if llean == "idk":
		#get the ray to always be facing the direction of the point
		if point[1] > ray1[0][1]:   #if the point is above
			#make it face upwards
			if slope1 > 0:
				llean = "r"
			else:
				llean = "l"
		#make it face upwards
		else:
			if slope1 > 0:
				llean = "l"
			else:
				llean = "r"

	if rlean == "idk":
		#get the ray to always be facing the direction of the point
		if point[1] > ray2[0][1]:   #if the point is above
			#make it face upwards
			if slope2 > 0:
				rlean = "r"
			else:
				rlean = "l"
		else:
			#make it face downwards
			if slope2 > 0:
				rlean = "l"
			else:
				rlean = "r"
	

	# check if intersection point lies on both rays
	if is_point_on_ray(ray1, point, llean) and is_point_on_ray(ray2, point, rlean):
		return point
	else:
		return


func CheckCircleEvent(focus_site_idx : int) -> void:
	if focus_site_idx < 2 or focus_site_idx > len(beachline)-2:
		return
	
	var left_arc = beachline[focus_site_idx-2]
	var right_arc = beachline[focus_site_idx+2]

	if left_arc == right_arc:
		return

	#left_edge = self.beachline[focus_site_idx-1]
	#right_edge = self.beachline[focus_site_idx+1]

	var circumcenter = rayIntersection(focus_site_idx-1, focus_site_idx+1)
	if circumcenter:
		#if there is another intersection at the same point
		#if Volornoi.dist(circumcenter, self.beachline[focus_site_idx-1]) < .001 or Volornoi.dist(circumcenter, self.beachline[focus_site_idx+1]) < .001:
		if dist(circumcenter, beachline[focus_site_idx-1]) < .001 or dist(circumcenter, beachline[focus_site_idx+1]) < .001:
			removeArc(siteLst[floor(focus_site_idx/2.0)])
			return
		
		var radius = dist(circumcenter, beachline[focus_site_idx])
		#if circumcenter[1] + radius < (sweepline - .001):  #the .001 is for float calculation errors incase it matches the sweepline
		#the .001 is for float calculation errors incase it matches the sweepline
		#if circumcenter[1] + radius < (self.sweepline - .001) or (left_arc in self.root and self.beachline[focus_site_idx] in self.root and right_arc in self.root and circumcenter[1] < 0):
		if circumcenter[1] + radius < (sweepline - .001) or (left_arc in root and beachline[focus_site_idx] in root and right_arc in root and circumcenter[1] < 0):
			return
		#e = Event(self.siteLst[focus_site_idx//2], 1, circumcenter[1] + radius, self.beachline[focus_site_idx]) #create a new circle event
		##print("Sweepline to be added: ", circumcenter[1] + radius)
		var e : event = event.new(siteLst[floor(focus_site_idx/2.0)], 1, float(circumcenter[1] + radius), beachline[focus_site_idx]) #create a new circle event
		eventQueue.add(e)

	#calculates the x intersection between two points
func site_intersect(site1 : Array, site2 : Array, sweepline : float, lean : String) -> float:
	if sweepline == site1[1] or sweepline == site2[1]:
		sweepline += .0001
	#h, k, p format
	var equ1 = [site1[0], (site1[1]+sweepline)/2.0, 2.0*(site1[1]-sweepline)]
	var equ2 = [site2[0], (site2[1]+sweepline)/2.0, 2.0*(site2[1]-sweepline)]
	#create a polynomial in the format ax^2 +bx + c to find the zeros
	var poly = [(1.0/equ1[2])-(1/equ2[2]), ((-equ1[0]*2.0)/equ1[2])-((-equ2[0]*2.0)/equ2[2]), (((equ1[0]**2)+(equ1[1]*equ1[2]))/equ1[2])-(((equ2[0]**2.0)+(equ2[1]*equ2[2]))/equ2[2])]
	
	if poly[0] == 0:
		return abs(poly[2]/poly[1])
		# return [abs(poly[2]/poly[1]), -1]
	#calculate the zeros of the polygon
	var discriminant = sqrt(poly[1]**2 - (4*poly[0]*poly[2]))
	var denominator = float(2*poly[0])
	var intersections = [(-poly[1]+discriminant)/denominator, (-poly[1]-discriminant)/denominator]
	
	intersections.sort()
	if lean == "r":
		return intersections[1]
		#intersections[0] = -1
	elif lean == "l":
		return intersections[0]
		#intersections[1] = -1
	else:   #incase the edge is idk
		#return the in bounds edge
		if 0 < intersections[0] or intersections[0] > self.size[1]: # If the first intersection is inside of the boundaries
			return intersections[0]
		else:	# The first intersection is invalid so the second intersection is chosen.
			return intersections[1]
	#return intersections

func addArc(target_site) -> void:
	#print("target site: ", target_site)
	# find the parabola that the target site intersects
	var chosen_site = [0] #index of the chosen_site
	var largest_y : float = -1.0
	var completed_pnts = [] #due to their being multiple copies of an point in the beachline you have to check to see if the point wasn't already tested
	#for beachIdx in range(0, len(self.beachline), 2):   
	for beachIdx in range(len(beachline)-1, -1, -1):#search the list in a reversed format due to the fact that when a new site is inserted it should be inserted to the last point of the beachline.
		if beachIdx % 2 == 0:
			var site = beachline[beachIdx]
			if (site not in completed_pnts) and (site != [-1,-1]) and (site[1] != target_site[1]):    #1,1 is the funcault. If site == target site's y then there is no possible collision
				var y : float = ((target_site[0] - site[0])**2.0) / (2.0 * (site[1] -
															target_site[1])) + ((target_site[1] + site[1]) / 2.0)
				if abs(largest_y - y) < .002: #range due to floating point inprecision
					chosen_site.append(beachIdx)  #turn chosen site into a list if there are multiple collisions
				elif largest_y < y:
					chosen_site = [beachIdx]
					largest_y = y
				completed_pnts.append(site)
	#del completed_pnts
	completed_pnts = null
	
	if largest_y < 0: #no arcs were collided with
		#print("No Arcs Collided with")
		#var siteIdx = 0
		# a = [-1,-1]
		# b = target_site
		# c = [-1,-1]

		# #-1,-1 is the signal of a collision with the floor(borderline)
		# leftEdge = [-1,-1]
		# rightEdge = [-1,-1]
		root.append(target_site)
		#self.beachline[siteIdx:siteIdx] = [target_site,[-1,-1]]
		if len(beachline) == 0:    #if the beachline is empty
			beachline.append_array([target_site])
			siteLst.append(siteCounter)
			siteCounter += 1
		else:
			#insert the root site into the beachline, in a position determined by the x(sorted)
			for beachIdx in range(0, len(beachline), 2): 
				if beachline[beachIdx][0] > target_site[0]:
					#var site = self.beachline[beachIdx]
					#self.beachline[beachIdx:beachIdx] = [target_site, [-1,-1]]
					beachline = extendAtIndex(beachline, [target_site, [-1,-1]], beachIdx)
					#both the siteLst and leans list are half of the beachline
					#edgeIdx = beachIdx//2
					#var edgeIdx = floor(beachIdx//2)	#Parser bug (please report): Trying to check compatibility of unset value type | I just have an extra //
					var edgeIdx = floor(beachIdx/2.0)	#Parser bug (please report): Trying to check compatibility of unset value type
					#self.siteLst[edgeIdx:edgeIdx] = [self.siteCounter]  #add the site
					siteLst = extendAtIndex(siteLst, [siteCounter], edgeIdx)
					siteCounter += 1
					leans = extendAtIndex(leans, ["idk"], edgeIdx)   #add the lean
					
					#if self.beachline[beachIdx+2] not in self.root:
					#if self.beachline[beachIdx+2]:
					CheckCircleEvent(beachIdx+2)  #index of site to the right
					
					CheckCircleEvent(beachIdx-2)#index of site to the left. If there is no site it will return None
					
					#self.CheckCircleEvent(chosen_site[1] + 4)  #index of c
					break
			#incase the edge is larger than the largest root
			if beachline[-1][0] < target_site[0]:
				beachline.append_array([[-1,-1], target_site])
				siteLst.append(siteCounter)
				siteCounter += 1
				leans.append("idk")   #some random value
				var beachIdx = len(beachline)-3
				#if self.beachline[beachIdx] not in self.root:
				CheckCircleEvent(beachIdx)  #index of site to the left. It is three as list start from zero and the len will return 1 value too high

	
	elif len(chosen_site) > 1:  #if the target site is on the intersection between two other arcs
		#print("Special intersection")
		
		var a = beachline[chosen_site[1]]
		var b = target_site
		var c = beachline[chosen_site[0]]
		
		#print("Chosen Site A: ", a)
		#print("Chosen Site C: ", c)
		# remove event that completes parabolas for the chosen sites( if present )
		#aSiteId = self.siteLst[chosen_site[1]//2]
		var aSiteId = siteLst[floor(chosen_site[1]/2.0)]
		#cSiteId = self.siteLst[chosen_site[0]//2]
		var cSiteId = siteLst[floor(chosen_site[0]/2.0)]
		var idxs_for_deletion = []
		for eventIdx in range(len(eventQueue.queue)):
			var e = eventQueue.queue[eventIdx]
			if (e.type == 1) and ( e.siteIdx == aSiteId or e.siteIdx == cSiteId):      #FLAG FIX | I think I fixed it
				idxs_for_deletion.append(eventIdx)
		
		if idxs_for_deletion != []:
			#for i in sorted(idxs_for_deletion, reverse=True):
			idxs_for_deletion.reverse()
			for i in idxs_for_deletion:
				#del self.eventQueue.queue[i]
				eventQueue.queue.remove_at(i)
		
		var intersection_pnt = [target_site[0] , largest_y]
		#siteIdx = (chosen_site[0] + chosen_site[1])//2  #Find the edge index between the two site indexs
		var siteIdx = floor((chosen_site[0] + chosen_site[1])/2.0)  #Find the edge index between the two site indexs
		#edgeIdx = siteIdx//2
		var edgeIdx = floor(siteIdx/2.0)

		var startPoint = beachline.pop_at(siteIdx) #remove the edge
		#del self.leans[siteIdx//2]    #remove the edge
		leans.remove_at(floor(siteIdx/2.0))    #remove the edge
		
		#del self.leans[edgeIdx]
		
		if c in root and a in root:
			#del self.beachline[chosen_site[0]] #delete the extra -1,-1 edge. Because of the previous delete, the beachline has been shifted over by 1, making the site index the edge index. This will only work if the a site is to the left of the c site. Shouldn't happen though :-3
			#del self.leans[chosen_site[0]//2 - 1] #get the edge the corresponseds to the site. Because of the previous delete, the leanlst had been shifted left by 1
		
			#if the second point is a root then the edge will be -1,-1
			var midpoint = midpoint(a,c)
			var s1x = float(a[1]-c[1])
			var s1y = float(-(a[0]-c[0]))
			var slope1 : float	#godot specific
			
			if s1x != 0:
				slope1 = s1y/s1x
			else:
				slope1 = 1000000000# the more zeros the more accurate as it is a vertical line
			
			var b1 = float(midpoint[1] - slope1*midpoint[0])
			#create the end starting point
			startPoint = [float((0-b1)/slope1), 0]   #floor Collision
		
		var edge = [startPoint, intersection_pnt]
		#add the edges to their respective edge list
		cells[tuple(a)][0].append(edge)
		cells[tuple(c)][0].append(edge)
		
		#send each cell their respective neighbors
		cells[tuple(a)][1].append(c)
		cells[tuple(c)][1].append(a)
		
		#self.beachline[siteIdx:siteIdx] = [intersection_pnt, b, intersection_pnt]    #replace 1 edge with two edges and site
		beachline = extendAtIndex(beachline, [intersection_pnt, b, intersection_pnt], siteIdx)    #replace 1 edge with two edges and site
		
		#self.siteLst[edgeIdx:edgeIdx] = [self.siteCounter]   #Give the new site it's id
		siteLst = extendAtIndex(siteLst, [siteCounter], edgeIdx)   #Give the new site it's id
		siteCounter += 1

		var aLean = ""
		var cLean = ""
		#if the target site is right above the a site
		if target_site[0] == a[0]:
			if target_site[0] < c[0]:	#use the non-same x to determine the lean
				aLean = "l"
				cLean = "r"
			else:
				aLean = "r"
				cLean = "l"

		#if the target site is right above the c site
		elif target_site[0] == c[0]:
			if target_site[0] < a[0]:
				aLean = "r"
				cLean = "l"
			else:
				aLean = "l"
				cLean = "r"
				
		else:
			if a[0] < target_site[0]:
				aLean = "l"
				cLean = "r"
			else:
				aLean = "r"
				cLean = "l"
				

		#self.leans[edgeIdx:edgeIdx] = [aLean,cLean]
		leans = extendAtIndex(leans, [aLean,cLean], edgeIdx)
		#print("Add Arc")
		CheckCircleEvent(chosen_site[1])  #index of a
		CheckCircleEvent(chosen_site[1] + 4)  #index of c
	
	else:   #normal site creation and collision
		#find what side of the arc the target site is on
		var siteIdx = chosen_site[0]
		var site = beachline[siteIdx]

		#find the correct siteIdx of the arc 
		for beachIdx in range(0, len(beachline), 2):
			if beachline[beachIdx] == site:
				#check to see if the target site x is in between the edges
				var testRange = []
				if beachIdx < 2:
					testRange.append(0) #left x boundary
				else:
					testRange.append(site_intersect(site, beachline[beachIdx-2], target_site[1], leans[floor((beachIdx-1)/2.0)]))    #find the intersection between the left site and the site
					#testRange.append(beachline[beachIdx-1][0]) #get the edge to the left of the site

				if beachIdx > len(beachline)-2:
					testRange.append(size[0])  #right x boundary
				else:
					testRange.append(site_intersect(site, beachline[beachIdx+2], target_site[1], leans[floor((beachIdx+1)/2.0)]))    #find the intersection between the right site and the site
					#testRange.append(beachline[beachIdx+1][0]) #get the edge's x to the right of the site

				#check to see if the target site is in range
				if testRange[0] <= target_site[0] and testRange[1] >= target_site[0]:
					siteIdx = beachIdx
					break
		
		#print("Chosen Site: ", site)
		# remove event that completes parabola for the chosen site( if present )
		#siteId = self.siteLst[siteIdx//2]
		var siteId = siteLst[floor(siteIdx/2.0)]
		var idxs_for_deletion = []
		for eventIdx in range(len(eventQueue.queue)):      #FLAG FIX | I think I fixed it
			var e : event = eventQueue.queue[eventIdx]
			if e.type == 1 and e.siteIdx == siteId:
				idxs_for_deletion.append(eventIdx)
		
		if idxs_for_deletion != []:
			#for i in sorted(idxs_for_deletion, reverse=True):
			idxs_for_deletion.reverse()
			for i in idxs_for_deletion:
				#del self.eventQueue.queue[i]
				eventQueue.queue.remove_at(i)
		
		var a = site
		var b = target_site
		var c = site
		
		#edgeIdx = siteIdx//2
		var edgeIdx = floor(siteIdx/2.0)
		
		var intersection_pnt = [target_site[0] ,largest_y]
		var leftEdge = intersection_pnt     #Volornoi.midpoint(a,b)
		var rightEdge = intersection_pnt    #Volornoi.midpoint(b,c)
		#del self.beachline[siteIdx]     #remove site
		beachline.remove_at(siteIdx)     #remove site
		##del self.siteLst[edgeIdx//2]   #remove site
		#del self.siteLst[edgeIdx]       #remove site
		siteLst.remove_at(edgeIdx)       #remove site
		#del self.leans[edgeIdx]
		# if site in self.root and len(self.beachline) > siteIdx and self.beachline[siteIdx] == [-1,-1]:
		#     del self.beachline[siteIdx] #delete the extra -1,-1 edge
		#     del self.leans[edgeIdx] #the del wasn't hear before... I hope I actually fixed something ;-;
			
		#self.beachline[siteIdx:siteIdx] = [a, leftEdge, b, rightEdge, c]    #extend at the index: site_Idx
		beachline = extendAtIndex(beachline, [a, leftEdge, b, rightEdge, c], siteIdx)    #extend at the index: site_Idx
		
		#self.siteLst[edgeIdx:edgeIdx] = [self.siteCounter, self.siteCounter + 1, self.siteCounter + 2]   #add the three site with incrementally increasing id's
		siteLst = extendAtIndex(siteLst, [siteCounter, siteCounter + 1, siteCounter + 2], edgeIdx)   #add the three site with incrementally increasing id's   
		siteCounter += 3
		
		#self.leans[edgeIdx:edgeIdx] = ["l","r"]
		leans = extendAtIndex(leans, ["l","r"], edgeIdx)
		#print("Add Arc")
		CheckCircleEvent(siteIdx)  #index of a
		CheckCircleEvent(siteIdx + 4)  #index of c



func removeArc(siteIdx : int) -> void:
	var siteLstIdx = self.siteLst.find(siteIdx)
	var beachSiteIdx = siteLstIdx * 2
	var site = beachline[beachSiteIdx]    #i need to grab the correct site
	#print("Removing: ", site)
	var left_site = beachline[beachSiteIdx-2]
	var right_site = beachline[beachSiteIdx+2]

	#lSiteId = self.siteLst[(beachSiteIdx-2)//2]
	var lSiteId = siteLst[siteLstIdx-1]
	#rSiteId = self.siteLst[(beachSiteIdx+2)//2]
	var rSiteId = siteLst[siteLstIdx+1]
	
	var idxs_for_deletion = []
	for eventIdx in range(len(eventQueue.queue)):
		var e = eventQueue.queue[eventIdx]
		
		if (e.type == 1) and ( e.siteIdx == lSiteId or e.siteIdx == rSiteId or e.siteIdx == siteIdx):   #FLAG FIX | I do not know I fixed it
			idxs_for_deletion.append(eventIdx)
	
	if idxs_for_deletion != []:
		#for i in sorted(idxs_for_deletion, reverse=True):
		idxs_for_deletion.reverse()
		for i in idxs_for_deletion:
			#del self.eventQueue.queue[i]
			eventQueue.queue.remove_at(i)
		
	#slope 1 x and y
	var s1x = float(site[1]-left_site[1])
	var s1y = float(-(site[0]-left_site[0]))    #has to be negative for the creation of a perpendicular slope

	#slope 2 x and y
	var s2x = float(right_site[1]-site[1])
	var s2y = float(-(right_site[0]-site[0]))    #has to be negative for the creation of a perpendicular slope

	#get the first perpendicular equation
	#midpoint1 = Volornoi.midpoint(site, left_site)
	var midpoint1 = midpoint(site, left_site)
	var m1 : float	#godot specific
	if s1x != 0:
		m1 = float(s1y/s1x)
	else:
		m1 = 1000000000.0# the more zeros the more accurate as it is a vertical line
	var b1 = float(midpoint1[1] - m1*midpoint1[0])

	#get the second perpendicular equation
	#midpoint2 = Volornoi.midpoint(site, right_site)
	var midpoint2 = midpoint(site, right_site)
	var m2 : float # godot specific
	if s2x != 0:
		m2 = float(s2y/s2x)
	else:
		m2 = 1000000000.0# the more zeros the more accurate as it is a vertical line
	var b2 = float(midpoint2[1] - m2*midpoint2[0])

	#create a floor collision if any of the site pairs are root
	if site in root:
		if left_site in root and beachline[beachSiteIdx-1] == [-1,-1]:
			beachline[beachSiteIdx-1] = [float((0-b1)/m1), 0]   #floor Collision
		if right_site in root and beachline[beachSiteIdx+1] == [-1,-1]: 
			beachline[beachSiteIdx+1] = [float((0-b2)/m2), 0]   #floor Collision
	
	var x = float((b1-b2)/(m2-m1))
	var circumcenter = [x, m1*x+b1]    #y = mx + b | The intersection point between the two equations.
	#print("Circumcenter: ", circumcenter)
	
	var pos = beachSiteIdx - 1
	#edgePos = pos//2
	var edgePos = floor(pos/2.0)
	#new = False
	var left_edge	#godot specific
	var right_edge	#godot specific
	
	if circumcenter[0] < 0: #left boundary
		left_edge = [beachline[beachSiteIdx-1], [0, m1*0 + b1]]
		right_edge = [beachline[beachSiteIdx+1], [0, m2*0+ b2]]
		
		#If there is a ceiling collision then the program is completed and there is no need to compute the rest
		if left_edge[1][1] > size[1] or left_edge[1][1] < 0:     #ceiling/floor collision
			return
			#left_edge[1] = [(self.size[1]-b1)/m1, self.size[1]]
		if right_edge[1][1] > size[1] or right_edge[1][1] < 0:    #ceiling/floor collision
			return
			#right_edge[1] = [(self.size[1]-b2)/m2, self.size[1]]
		
		var falseEdge = false   #this variable is for setting a false edge in the case that a set if edges have to be removed in the middle of the beachline, while they collide outside of the beachline. The flag makes sure that an edge(that should never be used) is present to keep the site, edge ,site pattern of the beachline
		#find the border site to be removed(the site that is the end/start of the beachline)
		if beachSiteIdx-2 == 0:
			#delete the leftmost site
			#del self.beachline[beachSiteIdx-2]   #site
			beachline.remove_at(beachSiteIdx-2)   #site
			#edgePos = (beachSiteIdx-2)//2
			edgePos = floor((beachSiteIdx-2)/2.0)
			#del self.siteLst[edgePos]
			siteLst.remove_at(edgePos)
			pos -= 1
		elif beachSiteIdx+2 == len(beachline)-1:
			#delete the rightmost site
			#del self.beachline[beachSiteIdx+2]   #site
			beachline.remove_at(beachSiteIdx+2)   #site
			#edgePos = (beachSiteIdx+2)//2
			edgePos = floor((beachSiteIdx+2)/2.0)
			#del self.siteLst[edgePos]#lower the pos because the entire beachline has shifted left by 1
			siteLst.remove_at(edgePos)#lower the pos because the entire beachline has shifted left by 1
		else:
			falseEdge = true
		
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#del self.beachline[pos] #SITE
		beachline.remove_at(pos) #SITE
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#del self.siteLst[beachSiteIdx//2]   #remove site from sitelst. variable pos starts from the edge idx
		siteLst.remove_at(floor(beachSiteIdx/2.0))   #remove site from sitelst. variable pos starts from the edge idx
		#edgePos = pos//2
		edgePos = floor(pos/2.0)
		#del self.leans[edgePos] #remove first edge from leans
		leans.remove_at(edgePos) #remove first edge from leans
		#del self.leans[edgePos] #remove second edge from leans
		leans.remove_at(edgePos) #remove second edge from leans
		if falseEdge:
			beachline.insert(pos, [-2,-2]) #-2,-2 is the false edge pos flag
			leans.insert(edgePos, "DNE")   #stands for 'Does Not Exist'
	
	elif circumcenter[0] > size[0]:    #right boundary
		#print("Right Intersection")
		left_edge = [beachline[beachSiteIdx-1], [size[0], m1*size[0] + b1]]
		right_edge = [beachline[beachSiteIdx+1], [size[0], m2*size[0] + b2]]
		#If there is a ceiling collision then the program is completed and there is no need to compute the rest
		if left_edge[1][1] > size[1] or left_edge[1][1] < 0:     #ceiling/floor collision
			return
			#left_edge[1] = [(self.size[1]-b1)/m1, self.size[1]]
		if right_edge[1][1] > size[1] or right_edge[1][1] < 0:    #ceiling/floor collision
			return
			#right_edge[1] = [(self.size[1]-b2)/m2, self.size[1]]
		
		var falseEdge = false   #this variable is for setting a false edge in the case that a set if edges have to be removed in the middle of the beachline, while they collide outside of the beachline. The flag makes sure that an edge(that should never be used) is present to keep the site, edge ,site pattern of the beachline
		#find the border site to be removed(the site that is the end/start of the beachline)
		if beachSiteIdx-2 == 0:
			#delete the leftmost site
			#del self.beachline[beachSiteIdx-2]   #site
			beachline.remove_at(beachSiteIdx-2)   #site
			#edgePos = (beachSiteIdx-2)//2
			edgePos = floor((beachSiteIdx-2)/2.0)
			#del self.siteLst[edgePos]
			siteLst.remove_at(edgePos)
			pos -= 1
		elif beachSiteIdx+2 == len(beachline)-1:
			#delete the rightmost site
			#del self.beachline[beachSiteIdx+2]   #site
			beachline.remove_at(beachSiteIdx+2)   #site
			#edgePos = (beachSiteIdx+2)//2
			edgePos = floor((beachSiteIdx+2)/2.0)
			#del self.siteLst[edgePos]#lower the pos because the entire beachline has shifted left by 1
			siteLst.remove_at(edgePos)#lower the pos because the entire beachline has shifted left by 1
		else:
			falseEdge = true
		
		
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#del self.beachline[pos] #SITE
		beachline.remove_at(pos) #SITE
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#del self.siteLst[beachSiteIdx//2]   #remove site from sitelst. variable pos starts from the edge idx
		siteLst.remove_at(floor(beachSiteIdx/2.0))   #remove site from sitelst. variable pos starts from the edge idx
		#edgePos = pos//2
		edgePos = floor(pos/2.0)
		#del self.leans[edgePos] #remove first edge from leans
		leans.remove_at(edgePos) #remove first edge from leans
		#del self.leans[edgePos] #remove second edge from leans
		leans.remove_at(edgePos) #remove second edge from leans
		if falseEdge:
			beachline.insert(pos, [-2,-2]) #-2,-2 is the false edge pos flag
			leans.insert(edgePos, "DNE")   #stands for 'Does Not Exist'
			
	elif circumcenter[1] > size[1] :#or circumcenter[1] < 0:    #ceiling/floor collision. I decided to add this on instead of editing for now until I can do more testing
		#print("Ceiling limit passed")
		return
	elif circumcenter[1] < 0:   #floor collision
		#print("floor limit passed")
		###NOTICE###
		#this edge case fix assumes that the collision is occuring between two roots and 1 non-root point that caused the intersection. The point is also between the two root points <- The last sentence may not be nessasary
		var center_site = []
		left_edge = []
		right_edge = []
		
		var lFloorPnt	#godot specific
		var rFloorPnt	#godot specific
		#the point that each edge collides with the floor of y=0
		#for a floor collision to happen, at least two sites has to be root. Use the non-root site to determine the two floor collision points
		if left_site in root:
			#print("Left site")
			#the right site is the non-root site
			center_site = right_site
			#generate perpendicular equation between left and right sites for the left site collision
			#slope 1 x and y
			s1x = float((center_site[1]-left_site[1]))
			s1y = float(-(center_site[0]-left_site[0]))    #has to be negative for the creation of a perpendicular slope
			#get the first perpendicular equation
			midpoint1 = midpoint(center_site, left_site)
			if s1x != 0:
				m1 = float(s1y/s1x)
			else:
				m1 = 1000000000.0# the more zeros the more accurate as it is a vertical line
			b1 = float(midpoint1[1] - m1*midpoint1[0])
			lFloorPnt = [(-b1)/m1, 0]   #floor Collision
			rFloorPnt = [(-b2)/m2, 0]   #site and right_site floor Collision
			circumcenter = lFloorPnt
			
			#add a gap closing edge to the non-root site
			#self.cells[tuple(center_site)][0].append([lFloorPnt, rFloorPnt])
			#left_edge = [beachline[beachSiteIdx-1], lFloorPnt]
			left_edge = [lFloorPnt, rFloorPnt]
			right_edge = [beachline[beachSiteIdx+1], rFloorPnt]
			
			#add the edges to their respective edge list
			cells[tuple(site)][0].append(right_edge)
			#self.cells[tuple(right_site)][0].append(right_edge)
			cells[tuple(center_site)][0].append_array([[lFloorPnt, rFloorPnt], right_edge])
			
			#send each cell their respective neighbors
			cells[tuple(site)][1].append(center_site)
			#self.cells[tuple(right_site)][1].append(center_site)
			cells[tuple(center_site)][1].append(site)
		
		elif right_site in root:
			#print("Right site")
			#the left site is the non-root site
			center_site = left_site
			#generate perpendicular equation between left and right sites for the left site collision
			#slope 1 x and y
			s2x = float(right_site[1]-center_site[1])
			s2y = float(-(right_site[0]-center_site[0]))    #has to be negative for the creation of a perpendicular slope
			#get the first perpendicular equation
			midpoint2 = midpoint(right_site, center_site)
			if s2x != 0:
				m2 = float(s2y/s2x)
			else:
				m2 = 1000000000.0# the more zeros the more accurate as it is a vertical line
			b2 = float(midpoint2[1] - m2*midpoint2[0])
			lFloorPnt = [(-b1)/m1, 0]   #site and left_site floor Collision
			rFloorPnt = [(-b2)/m2, 0]   #floor Collision
			circumcenter = rFloorPnt
			#center_site = left_site
			#add a gap closing edge to the non-root site
			#self.cells[tuple(center_site)][0].append([lFloorPnt, rFloorPnt])
			#print("beachline: ", beachline)
			#print("beachSiteIdx: ", beachSiteIdx)
			left_edge = [beachline[beachSiteIdx-1], lFloorPnt]
			#right_edge = [beachline[beachSiteIdx+1], rFloorPnt]
			right_edge = [lFloorPnt, rFloorPnt]
			
			#add the edges to their respective edge list
			cells[tuple(site)][0].append(left_edge)
			#self.cells[tuple(right_site)][0].append(right_edge)
			cells[tuple(center_site)][0].append_array([[lFloorPnt, rFloorPnt], left_edge])
			
			#send each cell their respective neighbors
			cells[tuple(left_site)][1].append(center_site)
			#self.cells[tuple(right_site)][1].append(center_site)
			cells[tuple(center_site)][1].append(site)
		
		#left_edge = [self.beachline[beachSiteIdx-1], lFloorPnt]
		#right_edge = [self.beachline[beachSiteIdx+1], rFloorPnt]
		#copied from code block below. The only change was the lFloor and rFloor variables
		#replace old edges and site with new edge
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#del self.beachline[pos] #SITE
		beachline.remove_at(pos) #SITE
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#self.siteLst.remove(siteIdx)  #the edge pos is moved left by one for deleting the edges and can't be used to delete the site lst
		siteLst.erase(siteIdx)  #the edge pos is moved left by one for deleting the edges and can't be used to delete the site lst
		
		#remove old edge's directions while storing them to calculate the new edge's lean
		var lEdgeDir = leans.pop_at(edgePos)
		var rEdgeDir = leans.pop_at(edgePos)
		#create the new edge
		#self.beachline[pos:pos] = [circumcenter]
		beachline = extendAtIndex(beachline, [circumcenter], pos)
		#self.siteLst[edgePos:edgePos] = [self.siteCounter] #only a new edge is being created. Why am I adding a new site ID?
		#self.siteCounter += 1
		#calculate lean of edge based on last edges
		if lEdgeDir == rEdgeDir:    #like: r facing edge + right facing edge = right facing edge. Vise versa for left
			#self.leans[edgePos:edgePos] = [lEdgeDir]
			leans = extendAtIndex(leans ,[lEdgeDir], edgePos)
		else:
			#find the direction based on the highest point
			if beachline[beachSiteIdx-2][1] < beachline[beachSiteIdx][1]: #right greater than left
				#self.leans[edgePos:edgePos] = ["l"]
				leans = extendAtIndex(leans, ["l"], edgePos)
			else:   #left greater than right
				#self.leans[edgePos:edgePos] = ["r"]
				leans = extendAtIndex(leans, ["r"], edgePos)
		
		CheckCircleEvent(beachSiteIdx-2)    #index of left site
		CheckCircleEvent(beachSiteIdx)      #index of right site
		return
	else:   #no boundary was collided with
		left_edge = [beachline[beachSiteIdx-1], circumcenter]
		right_edge = [beachline[beachSiteIdx+1], circumcenter]
		#new = True
	#if new:
		#replace old edges and site with new edge
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#del self.beachline[pos] #SITE
		beachline.remove_at(pos) #SITE
		#del self.beachline[pos] #EDGE
		beachline.remove_at(pos) #EDGE
		#self.siteLst.remove(siteIdx)  #the edge pos is moved left by one for deleting the edges and can't be used to delete the site lst
		siteLst.erase(siteIdx)  #the edge pos is moved left by one for deleting the edges and can't be used to delete the site lst

		#remove old edge's directions while storing them to calculate the new edge's lean
		var lEdgeDir = leans.pop_at(edgePos)
		var rEdgeDir = leans.pop_at(edgePos)

		#create the new edge
		#self.beachline[pos:pos] = [circumcenter]
		beachline = extendAtIndex(beachline, [circumcenter], pos)
		#self.siteLst[edgePos:edgePos] = [self.siteCounter] #only a new edge is being created. Why am I adding a new site ID?
		#self.siteCounter += 1
		#calculate lean of edge based on last edges
		if lEdgeDir == rEdgeDir and (lEdgeDir != "idk" and rEdgeDir != "idk"):    #like: r facing edge + right facing edge = right facing edge. Vise versa for left
			#self.leans[edgePos:edgePos] = [lEdgeDir]
			leans = extendAtIndex(leans ,[lEdgeDir], edgePos)
		else:
			#find the direction based on the highest point
			if beachline[beachSiteIdx-2][1] < beachline[beachSiteIdx][1]: #right greater than left
				#self.leans[edgePos:edgePos] = ["l"]
				leans = extendAtIndex(leans, ["l"], edgePos)
			else:   #left greater than right
				#self.leans[edgePos:edgePos] = ["r"]
				leans = extendAtIndex(leans, ["r"], edgePos)
		
		CheckCircleEvent(beachSiteIdx-2)    #index of left site
		CheckCircleEvent(beachSiteIdx)      #index of right site
	# else:
	#     #remove old edges and site
	#     #pos -= 1   #only used with left leaning intersections
	#     del self.beachline[pos] #EDGE
	#     del self.beachline[pos] #SITE
	#     del self.beachline[pos] #EDGE
	#     del self.siteLst[edgePos]   #remove site from sitelst
	#     del self.leans[edgePos] #remove first edge from leans
	#     del self.leans[edgePos] #remove second edge from leans
	
	#add the edges to their respective edge list
	cells[tuple(left_site)][0].append(left_edge)
	cells[tuple(right_site)][0].append(right_edge)
	cells[tuple(site)][0].append_array([left_edge, right_edge])
	
	#send each cell their respective neighbors
	cells[tuple(left_site)][1].append(site)
	cells[tuple(right_site)][1].append(site)
	cells[tuple(site)][1].append_array([left_site, right_site])
	
	#print("Remove Arc")

var root := []  #contains every edge that is collides with the borderline/floor
var beachline := []   # beachline in form [site0, edge0, site1, edge1]
var leans := [] #contains the direction for every edge ( l = left, r = right)
var siteLst := []   #list of non-repeating interger ids for every site, allowing calling of the correct site
var siteCounter : int    #a integer counter that only increases. Is used for setting ids to all of the points. Allows for no duplication
var sweepline : float
var eventQueue : PriorityQueue
func generate() -> void:
	#self.root = []  #contains every edge that is collides with the borderline/floor
	root = []
	#self.beachline = []   # beachline in form [site0, edge0, site1, edge1]
	beachline = []
	#self.leans = [] #contains the direction for every edge ( l = left, r = right)
	leans = []
	#self.siteLst = []   #list of non-repeating interger ids for every site, allowing calling of the correct site
	siteLst = []
	#self.siteCounter = 0    #a integer counter that only increases. Is used for setting ids to all of the points. Allows for no duplication
	siteCounter = 0
	#self.sweepline = 0
	sweepline = 0
	#self.eventQueue = PriorityQueue.new()
	eventQueue = PriorityQueue.new()

	# set all of the sites as site events in the queue
	for point in pointLst:
		eventQueue.queue.append(event.new(-1, 0, point[1], point))
	#print("------------------")
	#print("Size: ", size)
	#print("------------------")
	while ( len(eventQueue.queue) > 0):  # run while the event queue is not empty
		#print("======================================")
		#print("Beachline before: ", beachline)
		var nextEvent = eventQueue.pop()
		sweepline = nextEvent.priority
		#print("Sweepline: ", sweepline)
		if nextEvent.type == 0:
			# site event
			#add to beachline
			addArc(nextEvent.site)
		else:
			# it is a circle event
			#remove from beachline
			removeArc(nextEvent.siteIdx)
	
		#print("Beachline after: ", beachline)
	
	#close final edges
	for edgeIdx in range(1,len(beachline), 2):
		#print(edgeIdx)
		#if self.leans[edgeIdx//2] != "DNE":
		if leans[floor(edgeIdx/2.0)] != "DNE":
			if beachline[edgeIdx] == [-1, -1] and len(beachline)-1 == edgeIdx:
				break
			var left_site = beachline[edgeIdx-1]
			var right_site = beachline[edgeIdx+1]
			var midpoint = beachline[edgeIdx]  #the edge startpoint is the midpoint
			#edgeLean = self.leans[edgeIdx//2]
			var edgeLean = leans[floor(edgeIdx/2.0)]
			#create a perpendicular equation between the sites of the edge
			
			var s1x = (left_site[1]-right_site[1])
			var s1y = -(left_site[0]-right_site[0])
			var m1 : float	#godot specific
			var b1 : float	#godot specific
			if s1x != 0:
				m1 = float(s1y/s1x)
			else:
				m1 = 1000000000.0# the more zeros the more accurate as it is a vertical line
			
			if midpoint == [-1,-1]: #if the edge is a root edge
				var mp = midpoint(left_site, right_site)
				b1 = mp[1] - m1*mp[0]
				#find the left edge collision
				#left wall collision is when x = 0 so remove mx and y = b
				if b1 > 0 and b1 < size[1]:  #inside of boundaries
					midpoint = [0, b1]
				else:
					if m1 > 0:  #if positive the left intersect will only involve the floor
						midpoint = [(-b1)/m1, 0]
					else:   #slope is negative and vise versa (intersect with ceiling)
						midpoint = [(self.size[1]-b1)/m1, self.size[1]]
			
			else:
				b1 = float(midpoint[1] - m1*midpoint[0])
			
			var endPoint	#godot specific
			if edgeLean == "l":
				endPoint = [0, m1*0 + b1]   #collision with left boundary
				if endPoint[1] > size[1]:    #if outside of the boundary
					endPoint = [(size[1]-b1)/m1, size[1]]    #ceiling Collision
				elif endPoint[1] < 0: #if negative
					endPoint = [(0-b1)/m1, 0]   #floor Collision
			else:   #edgeLean is right
				endPoint = [size[0], m1*size[0] + b1]   #collision with right boundary
				if endPoint[1] > size[1]:    #if outside of the boundary
					endPoint = [(size[1]-b1)/m1, size[1]]    #ceiling Collision
				elif endPoint[1] < 0: #if negative
					endPoint = [(0-b1)/m1, 0]   #floor Collision
			
			var edge = [midpoint, endPoint]
			#print("Edge: ", edge)
			
			#close the edges and add them to their respective edge list
			cells[tuple(left_site)][0].append(edge)
			cells[tuple(right_site)][0].append(edge)
			
			#send each cell their respective neighbors
			cells[tuple(left_site)][1].append(right_site)
			cells[tuple(right_site)][1].append(left_site)
			
		
	#print("Final Beachline: ", self.beachline)
	
	#turn all edgelist into polygons!
	for cell_name in cells:
		#print(str(cell_name) + " | Edges | ", cells[cell_name][0])
		orderEdges(cell_name)
		#I am thinking about having corner handling out here. Just add the one point to the end of the polygon list
	
	#add the corner point
	var cornerLst = [
		[0,0],              #bottom left
		[0, size[1]],  #top left
		[size[0], 0],  #bottom right
		size           #top right
	]
	#var idx = 0
	for corner in cornerLst:
		var cell_name = tuple(nearest_point(corner))
		if cells[cell_name][0][0][0] == corner[0] or cells[cell_name][0][0][1] == corner[1]:  #if the x's or y's are the same
			if corner not in cells[cell_name][0]:
				cells[cell_name][0].insert(0, corner)  #the corner may already be in the polygon
		else:
			if corner not in cells[cell_name][0]:
				cells[cell_name][0].append(corner)     #the corner may already be in the polygon
