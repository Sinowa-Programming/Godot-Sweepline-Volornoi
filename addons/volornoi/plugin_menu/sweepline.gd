@tool
extends Node


func execute(_pointLst : Array[Vector2], _size : Array) -> Dictionary:
	# Incase there is only one size in the point list
	if _pointLst.size() == 1:
		var out_dict = {
			_pointLst[0] : [
				[
					Vector2(0,0),
					Vector2(0, _size[1]),
					_size,
					Vector2(_size[0], 0)
				],[] ]
		}
		return out_dict
		
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
		cells[point] = [[],[]]   #first list contains edges(later polygons). The second contains neigbors


func yThenXSort(p1, p2):
	if p1[1] == p2[1]:
		return p1[0] < p2[0]
	else:
		return p1[1] < p2[1]


# Site event is type 0
# Circle event is type 1
class event:
	var siteIdx : int
	var type : int
	var priority : float
	var site : Vector2
	
	func _init(_siteIdx : int, _type : int, _priority : float, _site : Vector2=Vector2()) -> void:
		siteIdx = _siteIdx  # The unique site index for the event
		type = _type
		priority = _priority
		site = _site    # Only used for circle events


class PriorityQueue:
	var queue : Array[event]
	var last_event : event
	func _init() -> void:
		queue = []
		last_event = null
	
	func add(e : event) -> void:
		#stop duplicate events
		#if self.last_event:
#		if last_event != null:
#			if last_event.type == event.type and last_event.siteIdx == event.siteIdx and abs(last_event.priority-event.priority) < .001:
#				return
	
		#add event to queue
		if len(queue) > 0 and e.priority < queue[-1].priority:
			for i in range(len(queue)):
				if queue[i].priority > e.priority:
					queue.insert(i, e)
					break
		
		else:
			queue.append(e)
		
		last_event = e
		return
	
	func pop() -> event:  # returns a Event class object
		#return self.queue.pop(0)
		return queue.pop_front()


#sourceArr is the base array that the DataArr is added to
#DataArr is the iterable that is extended at the index
func extendAtIndex(sourceArr : Array, DataArr: Array, index : int):
	DataArr.reverse()
	for data in DataArr:
		sourceArr.insert(index,data)
	return sourceArr


func nearest_point(point : Vector2) -> Vector2:
	var smallestDist = 1000000000
	var pnt = []
	for pt in pointLst:
		var a = pow(point[0] - pt[0], 2) + pow(point[1] - pt[1], 2)
		if a < smallestDist:
			smallestDist = a
			pnt = pt
	return pnt


func unique_list(lst : Array) -> Array:	# Can't have nested typed arrays in gdscript
	var uni_lst : Array = []
	for item : Vector2 in lst:
		if item not in uni_lst:
			uni_lst.append(item)
	
	return uni_lst


func orderEdges(cell_name) -> void:
	var cell = cells[cell_name]
	# This function is the final step and I decided it will also handle cleaning up the data ( removing any duplicates )
	var unique: Array = []
	
	cell[1] = unique_list(cell[1])	# Removes the duplicates
	
	
	var polygon = []
	var lst = cell[0].duplicate(true)
	polygon.append_array(lst[0])
	lst.remove_at(0)
	
	for i in range(len(lst)):
		var old_len = len(lst)
		for j in range(len(lst)):
			var edge = lst[j]
			
			if edge[0] == polygon[0]:
				polygon.insert(0, edge[1])
				lst.remove_at(j)
				break
			if edge[1] == polygon[0]:
				polygon.insert(0, edge[0])
				lst.remove_at(j)
				break
			if edge[0] == polygon[-1]:
				polygon.append(edge[1])
				lst.remove_at(j)
				break
			if edge[1] == polygon[-1]:
				polygon.append(edge[0])
				lst.remove_at(j)
				break
		if old_len == len(lst): # No points were removed/ gap in edge list
			# If the point is a root, then the gap is most likely at the floor, so match the y's. I know that this english is bad(yes english is my first language)
			for j in range(len(lst)):
				var edge = lst[j]
				# Find the end point in the polygon that matches the detached edge's x
				if polygon[0][1] == edge[0][1]:
					polygon.insert(0, edge[0])
					polygon.insert(0, edge[1])
					lst.remove_at(j)
					break
				elif polygon[0][1] == edge[1][1]:
					polygon.insert(0, edge[1])
					polygon.insert(0, edge[0])
					lst.remove_at(j)
					break
				elif polygon[-1][1] == edge[0][1]:
					polygon.append_array(edge)
					lst.remove_at(j)
					break
				elif polygon[-1][1] == edge[1][1]:
					edge.reverse()
					polygon.append_array(edge)
					lst.remove_at(j)
					break
			# Find the matching point that has the same x as the detached edge
			for j in range(len(lst)):
				var edge = lst[j]
				# Find the end point in the polygon that matches the detached edge's x
				if polygon[0][0] == edge[0][0]:
					polygon.insert(0, edge[0])
					polygon.insert(0, edge[1])
					lst.remove_at(j)
					break
				elif polygon[0][0] == edge[1][0]:
					polygon.insert(0, edge[1])
					polygon.insert(0, edge[0])
					lst.remove_at(j)
					break
				elif polygon[-1][0] == edge[0][0]:
					polygon.append_array(edge)
					lst.remove_at(j)
					break
				elif polygon[-1][0] == edge[1][0]:
					edge.reverse()
					polygon.append_array(edge)
					lst.remove_at(j)
					break
	
	
	# Remove extra point that points to the polygon starting point
	if polygon[0] == polygon[-1]:
		polygon.remove_at(len(polygon)-1)
	
	cell[0] = polygon


# Calculate the distance between 2 points
func dist(p1 : Vector2, p2 : Vector2) -> float:
	return sqrt(pow(p2[0]-p1[0],2) + pow(p2[1]-p1[1],2))


func midpoint(p1 : Vector2, p2 : Vector2) -> Vector2:
	return Vector2( (p1[0]+p2[0])/2.0, (p1[1]+p2[1])/2.0 )


func dot(v1, v2) -> float:
	var sum = 0
	for i in range(len(v1)):
		sum += v1[i] * v2[i]

	return sum


func diff(p1 : Vector2, p2 : Vector2) -> Vector2:
	return Vector2( p1[0] - p2[0], p1[1] - p2[1] )


# Checks if the rays intersect, returns a point if true; null if false
func rayIntersection(leftEdgeIdx : int, rightEdgeIdx : int):
	var p1 : Vector2 = beachline[leftEdgeIdx-1]
	var p2 : Vector2 = beachline[leftEdgeIdx+1]  # p2 is p1 for the Right Edge
	var p3 : Vector2 = beachline[rightEdgeIdx+1]
	
	var llean : String = leans[floor(leftEdgeIdx/2.0)]
	var rlean : String = leans[floor(rightEdgeIdx/2.0)]
	
	#IDK if this is nessasary, but better safe than sorry
	if llean == "DNE" or rlean == "DNE":
		return
	
	"""
	Finds the intersection between two rays in vector format.
	
	Args:
	ray_a: An array of [Vector2(x0, y0), Vector2(dx, dy)] representing the first ray.
	ray_b: An array of [Vector2(x0, y0), Vector2(dx, dy)] representing the second ray.
	
	Returns:
	A point if the rays intersect, or null if no intersection.
	"""
	
	var ray1 : Array[Vector2] = [beachline[leftEdgeIdx]]
	var ray2 : Array[Vector2] = [beachline[rightEdgeIdx]]
	
	if ray1[0] == Vector2(-1,-1):  # If root
		ray1[0] = midpoint(p1,p2)
	
	if ray2[0] == Vector2(-1,-1):  # If root
		ray2[0] = midpoint(p2,p3)
	
	
	# Slope 1 x and y
	var s1x : float = float(p2[1]-p1[1])
	var s1y : float = float(-(p2[0]-p1[0]))    # Has to be negative for the creation of a perpendicular slope
	
	# Slope 2 x and y
	var s2x = float(p3[1]-p2[1])
	var s2y = float(-(p3[0]-p2[0]))    # Has to be negative for the creation of a perpendicular slope
	if s1y == s2y and s1x == s2x:   # Check if the slopes are equal (rays are parallel)
		return
	
	var slope1 : float
	var slope2 : float
	if s1x != 0:
		slope1 = float(s1y/s1x)
	else:
		slope1 = 1000000000.0# The more zeros the more accurate as it is a vertical line
	
	
	if s2x != 0:
		slope2 = float(s2y/s2x)
	else:
		slope2 = 1000000000.0# The more zeros the more accurate as it is a vertical line
	
	ray1.append( Vector2(s1x, s1y) )
	
	ray2.append( Vector2(s2x, s2y) )
	
	# Ray1 and ray2 are in the format [origin, direction]
	# Origin is a tuple (x, y) representing the starting point of the ray
	# Direction is a tuple (dx, dy) representing the direction of the ray
	
	# Find intersection point of the two lines that the rays extend from
	var x1 : float = ray1[0][0]
	var y1 : float = ray1[0][1]
	var x2 : float = ray2[0][0]
	var y2 : float = ray2[0][1]
	
	var dx1 : float = ray1[1][0]
	var dx2 : float = ray2[1][0]
	
	
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
	
	
	var point : Vector2 = Vector2(x, y)
	
	if point[1] > 0:
		# When two sites that define a ray are root then the edge may be facing downwards (due to previous under floor collisions), and won't be idk.
		if (beachline[leftEdgeIdx] == Vector2(-1,-1) and (p1 in root or p2 in root)):   # p1 and p2 make up the first ray
			llean = "idk"
		
		if (beachline[rightEdgeIdx] == Vector2(-1,-1) and (p2 in root or p3 in root)):   # p2 and p3 make up the second ray
			rlean = "idk"
	
	
	# If a lean is idk then the lean is a root. define their lean here.
	if llean == "idk":
		# Get the ray to always be facing the direction of the point
		if point[1] > ray1[0][1]:   # If the point is above
			# Make it face upwards
			if slope1 > 0:
				llean = "r"
			else:
				llean = "l"
		# Make it face upwards
		else:
			if slope1 > 0:
				llean = "l"
			else:
				llean = "r"

	if rlean == "idk":
		# Get the ray to always be facing the direction of the point
		if point[1] > ray2[0][1]:   # If the point is above
			# Make it face upwards
			if slope2 > 0:
				rlean = "r"
			else:
				rlean = "l"
		else:
			# Make it face downwards
			if slope2 > 0:
				rlean = "l"
			else:
				rlean = "r"
	
	
	# Correct the ray direction
	if (llean == "l" and ray1[1][0] > 0) or (llean == "r" and ray1[1][0] < 0):
			# Invert the ray to make it face the right direction
			ray1[1][0] *= -1
			ray1[1][1] *= -1
	elif ray1[1][0] == 0:
		# Make the ray face the point
		if (point[1] > ray1[0][1] and ray1[1][1] < 0) or (point[1] < ray1[0][1] and ray1[1][1] > 0):
			ray1[1][1] *= -1

	if (rlean == "l" and ray2[1][0] > 0) or (rlean == "r" and ray2[1][0] < 0):
			# Invert the ray to make it face the right direction
			ray2[1][0] *= -1
			ray2[1][1] *= -1
	elif ray2[1][0] == 0:
		# Make the ray face the point
		if (point[1] > ray2[0][1] and ray2[1][1] < 0) or (point[1] < ray2[0][1] and ray2[1][1] > 0):
			ray2[1][1] *= -1
		

	# Ray intersection algorithm obtained from https://stackoverflow.com/questions/2931573/determining-if-two-rays-intersect
	# If zero then the rays do not intersect
	var det : float = float(ray2[1][0] * ray1[1][1] - ray2[1][1] * ray1[1][0])
	
	if det == 0:
		return
	
	var u : float = float( ((ray2[0][1] - ray1[0][1]) * ray2[1][0] - (ray2[0][0] - ray1[0][0]) * ray2[1][1]) / det )
	var v : float = float ( ((ray2[0][1] - ray1[0][1]) * ray1[1][0] - (ray2[0][0] - ray1[0][0]) * ray1[1][1]) / det )
	
	# Incase a ray has it's starting point on the intersection point
	if dist(point, ray1[0]) < .000001:
		u=1
	if dist(point, ray2[0]) < .000001:
		v=1

	# Check if intersection point lies on both rays
	if u >= 0 and v >= 0:   # Greater than or equal to as sometimes the ray origin is on the point position that the other ray collides with
		return point
	else:
		return


func CheckCircleEvent(focus_site_idx : int) -> void:
	if focus_site_idx < 2 or focus_site_idx > len(beachline)-2:
		return
	
	var left_arc : Vector2 = beachline[focus_site_idx-2]
	var right_arc : Vector2 = beachline[focus_site_idx+2]
	
	if left_arc == right_arc:
		return
	
	var circumcenter = rayIntersection(focus_site_idx-1, focus_site_idx+1)
	
	if circumcenter:
		# If there is another intersection at the same point
		if dist(circumcenter, beachline[focus_site_idx-1]) < .001 or dist(circumcenter, beachline[focus_site_idx+1]) < .001:
			removeArc(siteLst[floor(focus_site_idx/2.0)])
			return
		
		var radius = dist(circumcenter, beachline[focus_site_idx])
		if circumcenter[1] + radius < (sweepline - .001):
			return
		
		var e : event = event.new(siteLst[floor(focus_site_idx/2.0)], 1, float(circumcenter[1] + radius), beachline[focus_site_idx]) #create a new circle event
		eventQueue.add(e)

# Calculates the x value of the intersection between two points
func site_intersect(site1 : Vector2, site2 : Vector2, sweepline : float, lean : String) -> float:
	if sweepline == site1[1] or sweepline == site2[1]:
		sweepline += .0001
	# h, k, p format
	var equ1 : Array[float] = [site1[0], (site1[1]+sweepline)/2.0, 2.0*(site1[1]-sweepline)]
	var equ2 : Array[float] = [site2[0], (site2[1]+sweepline)/2.0, 2.0*(site2[1]-sweepline)]
	# Create a polynomial in the format ax^2 +bx + c to find the zeros
	var poly : Array[float] = [(1.0/equ1[2])-(1/equ2[2]), ((-equ1[0]*2.0)/equ1[2])-((-equ2[0]*2.0)/equ2[2]), (((equ1[0]**2)+(equ1[1]*equ1[2]))/equ1[2])-(((equ2[0]**2.0)+(equ2[1]*equ2[2]))/equ2[2])]
	
	if poly[0] == 0:
		return abs(poly[2]/poly[1])
		# return [abs(poly[2]/poly[1]), -1]
	#calculate the zeros of the polygon
	var discriminant : float = sqrt(poly[1]**2 - (4*poly[0]*poly[2]))
	var denominator : float = float(2*poly[0])
	var intersections : Array[float] = [(-poly[1]+discriminant)/denominator, (-poly[1]-discriminant)/denominator]
	
	intersections.sort()
	
	if lean == "r":
		return intersections[1]
	elif lean == "l":
		return intersections[0]
	else:   # Incase the edge is idk
		# Return the in bounds edge
		# 1 Floor and ceiling
		if size[2] < intersections[0] or intersections[0] > size[3]: # If the first intersection is inside of the boundaries
			return intersections[0]
		else:   # The first intersection is invalid so the second intersection is chosen.
			return intersections[1]

func addArc(target_site : Vector2) -> void:
	#print("target site: ", target_site)
	# Find the parabola that the target site intersects
	var chosen_site : Array[int] = [0] #index of the chosen_site
	var y_collision : float = -10000000000000000.0
	var beachline_len : int = beachline.size()
	for beachIdx : int in range(0, beachline_len, 2):
		var site : Vector2 = beachline[beachIdx]
		# Check to see if the target site x is in between the site collision points
		var testRange : Array[float] = []
		var border : Array[bool] = [true, true]  # Flag if the left/right border is collided with. Prevents the special collision from happening. border = [left flag, right flag]
		if beachIdx < 2 or leans[floor( (beachIdx-1)/2.0 )] == "DNE":    # Check if there is a wall or if the left edge exist
			testRange.append(size[0]) # Left x boundary
			border[0] = false
		else:
			testRange.append( site_intersect(site, beachline[beachIdx-2], target_site[1], leans[floor( (beachIdx-1)/2.0 )] ))    # Find the intersection between the left site and the site
		
		if beachIdx > beachline_len-2:    # Check if there is a wall
			testRange.append(size[1])  # Right x boundary
			border[0] = false
		elif leans[floor( (beachIdx+1)/2.0 )] == "DNE":    # Check if the right edge exist
			testRange.append(size[0]) #1 Left x boundary
			border[0] = false
		else:
			testRange.append(site_intersect(site, beachline[beachIdx+2], target_site[1], leans[floor( (beachIdx+1)/2.0 )]))    # Find the intersection between the right site and the site
		
		
		# Edge case if the site collides on a collison point. Check the 'special intersection' branch.
		if (border[1] and ( abs(testRange[1] - target_site[0]) < .002 )) or ( border[0] and ( abs(testRange[0] - target_site[0]) < .002 ) ):   # Range due to floating point inprecision
			# Zero division error if the y's are the same
			if target_site[1] != site[1]:
				var y : float = float( ((target_site[0] - site[0])**2) / (2 * (site[1] -
															target_site[1])) + ((target_site[1] + site[1]) / 2) )
				# If the y is so low then they are not colliding
				if y > y_collision:
					y_collision = y
			chosen_site = [beachIdx+2, beachIdx]
			break
		
		# Check to see if the target site is in the range
		if testRange[0] <= target_site[0] and testRange[1] >= target_site[0]:
			# Zero division error if the y's are the same
			if target_site[1] != site[1]:
				var y : float = float( ((target_site[0] - site[0])**2) / (2 * (site[1] -
															target_site[1])) + ((target_site[1] + site[1]) / 2) )
				# If the y is so low then they are not colliding
				if y > y_collision:
					y_collision = y
			

			chosen_site = [beachIdx]
			break
	
	if len(chosen_site) == 1 and y_collision == -10000000000000000: #no arcs were collided with
		#print("No Arcs Collided with")
		#var siteIdx = 0
		# a = Vector2(-1,-1)
		# b = target_site
		# c = Vector2(-1,-1)

		# #-1,-1 is the signal of a collision with the floor(borderline)
		# leftEdge = Vector2(-1,-1)
		# rightEdge = Vector2(-1,-1)
		root.append(target_site)
		#self.beachline[siteIdx:siteIdx] = [target_site,Vector2(-1,-1)]
		if len(beachline) == 0:    # If the beachline is empty
			beachline.append_array([target_site])
			siteLst.append(siteCounter)
			siteCounter += 1
		elif y_collision == -10000000000000000.0:   # No arcs were able to be collided with
			if beachline[0][0] < target_site[0]:
				beachline.append_array([Vector2(-1,-1), target_site])
				siteLst.append(siteCounter)
				siteCounter += 1
				leans.append("idk")   # Some random value
				var beachIdx : int = len(beachline)-3
				CheckCircleEvent(beachIdx)  # Index of site to the left. It is three as list start from zero and the len will return 1 value too high
			else:   # The new arc is smaller than the value
				beachline = extendAtIndex(beachline, [target_site, Vector2(-1,-1)], 0)
				siteLst.append(siteCounter)
				siteCounter += 1
				leans = extendAtIndex(leans, ["idk"], 0)   # Makes the ray aim towards the given collision point
				CheckCircleEvent(0)  # Index of site to the left.
		else:
			var siteIdx : int = chosen_site[0]
			var site : Vector2 = beachline[siteIdx]
			var edgeIdx : int = floor(siteIdx/2)
			
			# Remove event that completes parabola for the chosen site( if present )
			var siteId : int = siteLst[floor(siteIdx/2.0)]
			var idxs_for_deletion : Array[int] = []
			for eventIdx : int in range(len(eventQueue.queue)):      # FLAG FIX | I think I fixed it
				var e : event = eventQueue.queue[eventIdx]
				if e.type == 1 and e.siteIdx == siteId:
					idxs_for_deletion.append(eventIdx)
			
			if idxs_for_deletion != []:
				idxs_for_deletion.reverse()
				for i : int in idxs_for_deletion:
					eventQueue.queue.remove_at(i)
			
			site = beachline[siteIdx]
			var intersection_pnt : Vector2 = Vector2( target_site[0] ,y_collision )
			beachline.remove_at(siteIdx)     # Remove site
			siteLst.remove_at(edgeIdx)       # Remove site
			
			beachline = extendAtIndex(beachline, [site, intersection_pnt, target_site, intersection_pnt, site], siteIdx)    # Extend at the index: site_Idx
			siteLst = extendAtIndex(siteLst, [siteCounter, siteCounter + 1, siteCounter + 2], edgeIdx)   # Add the three site with incrementally increasing id's   
			siteCounter += 3
			
			leans = extendAtIndex(leans, ["l","r"], edgeIdx)
			
			CheckCircleEvent(siteIdx+4)  # Index of site to the right
			CheckCircleEvent(siteIdx)# Index of site to the left. If there is no site it will return None
	
	
	elif len(chosen_site) > 1:  # If the target site is on the intersection between two other arcs
		#print("Special intersection")
		
		var a : Vector2 = beachline[chosen_site[1]]
		var b : Vector2 = target_site
		var c : Vector2 = beachline[chosen_site[0]]
		
		#print("Chosen Site A: ", a)
		#print("Chosen Site C: ", c)
		# Remove event that completes parabolas for the chosen sites( if present )
		var aSiteId : int = siteLst[floor(chosen_site[1]/2.0)]
		var cSiteId : int = siteLst[floor(chosen_site[0]/2.0)]
		var idxs_for_deletion : Array[int] = []
		for eventIdx : int in range(len(eventQueue.queue)):
			var e : event = eventQueue.queue[eventIdx]
			if (e.type == 1) and ( e.siteIdx == aSiteId or e.siteIdx == cSiteId):      # FLAG FIX | I think I fixed it
				idxs_for_deletion.append(eventIdx)
		
		if idxs_for_deletion != []:
			#for i in sorted(idxs_for_deletion, reverse=True):
			idxs_for_deletion.reverse()
			for i : int in idxs_for_deletion:
				#del self.eventQueue.queue[i]
				eventQueue.queue.remove_at(i)
		
		var intersection_pnt : Vector2 = Vector2(target_site[0] , y_collision)
		var siteIdx : int = floor((chosen_site[0] + chosen_site[1])/2.0)  # Find the edge index between the two site indexs
		var edgeIdx : int = floor(siteIdx/2.0)

		var startPoint : Vector2 = beachline.pop_at(siteIdx) # Remove the edge
		leans.remove_at(floor(siteIdx/2.0))    # Remove the edge
		
		if startPoint == Vector2(-1,-1) or startPoint[1] < 0:
			var slope1 : float
			# If the second point is a root then the edge will be -1,-1
			var midpoint : Vector2 = midpoint(a,c)
			var s1x : float = float(a[1]-c[1])
			var s1y : float = float ( -(a[0]-c[0]) )
			if s1x != 0:
				slope1 = s1y/s1x
			else:
				slope1 = 1000000000# The more zeros the more accurate as it is a vertical line
			
			var b1 : float = midpoint[1] - slope1*midpoint[0]
			# Create the end starting point
			startPoint = Vector2( (size[2]-b1)/slope1, size[2] )   # Floor Collision #1 I just added the size[2] without any deep math checks. May be a problem
			
		if intersection_pnt[1] > size[2]:
			var edge : Array[Vector2] = [startPoint, intersection_pnt]
			# Add the edges to their respective edge list
			cells[a][0].append(edge)
			cells[c][0].append(edge)
			
			# Send each cell their respective neighbors
			cells[a][1].append(c)
			cells[c][1].append(a)
		
		beachline = extendAtIndex(beachline, [intersection_pnt, b, intersection_pnt], siteIdx)    # Replace 1 edge with two edges and site
		
		siteLst = extendAtIndex(siteLst, [siteCounter], edgeIdx)   # Give the new site it's id
		siteCounter += 1
		
		var aLean : String = ""
		var cLean : String = ""
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
				
		
		leans = extendAtIndex(leans, [aLean,cLean], edgeIdx)
		#print("Add Arc")
		CheckCircleEvent(chosen_site[1])  # Index of a
		CheckCircleEvent(chosen_site[1] + 4)  # Index of c
	
	else:   # Normal site creation and collision
		# Add to root if the collision is under the floor
		if y_collision < 0:
			root.append(target_site)
		# Find what side of the arc the target site is on
		var siteIdx : int = chosen_site[0]
		var site : Vector2 = beachline[siteIdx]
		
		#print("Chosen Site: ", site)

		# Remove event that completes parabola for the chosen site( if present )
		var siteId : int = siteLst[floor(siteIdx/2.0)]
		var idxs_for_deletion : Array[int] = []
		for eventIdx : int in range(len(eventQueue.queue)):      # FLAG FIX | I think I fixed it
			var e : event = eventQueue.queue[eventIdx]
			if e.type == 1 and e.siteIdx == siteId:
				idxs_for_deletion.append(eventIdx)
		
		if idxs_for_deletion != []:
			for i : int in idxs_for_deletion:
				eventQueue.queue.remove_at(i)
		
		var a : Vector2 = site
		var b : Vector2 = target_site
		var c : Vector2 = site
		
		var edgeIdx = floor(siteIdx/2.0)
		
		var intersection_pnt : Vector2 = Vector2(target_site[0], y_collision)
		var leftEdge : Vector2 = intersection_pnt
		var rightEdge : Vector2 = intersection_pnt
		
		beachline.remove_at(siteIdx)     # Remove site
		siteLst.remove_at(edgeIdx)       # Remove site
		
		beachline = extendAtIndex(beachline, [a, leftEdge, b, rightEdge, c], siteIdx)    # Extend at the index: site_Idx
		
		siteLst = extendAtIndex(siteLst, [siteCounter, siteCounter + 1, siteCounter + 2], edgeIdx)   # Add the three site with incrementally increasing id's   
		siteCounter += 3
		
		leans = extendAtIndex(leans, ["l","r"], edgeIdx)
		#print("Add Arc")
		
		CheckCircleEvent(siteIdx)  #index of a
		CheckCircleEvent(siteIdx + 4)  #index of c


func closeEdge(edgeIdx : int) -> void:
	var left_site : Vector2 = beachline[edgeIdx-1]
	var right_site : Vector2 = beachline[edgeIdx+1]
	var midpoint  : Vector2 = beachline[edgeIdx]  # The edge startpoint is the midpoint
	var edgeLean : String = leans[floor(edgeIdx/2.0)]
	
	#Create a perpendicular equation between the sites of the edge
	var s1x : float = (left_site[1]-right_site[1])
	var s1y : float = -(left_site[0]-right_site[0])
	
	var m1 : float	#godot specific
	var b1 : float	#godot specific
	if s1x != 0:
		m1 = float(s1y/s1x)
		# If the ray is under the border and is facing downwards then there is no visible collision
		if beachline[edgeIdx][1] < size[2]:
			if m1 < 0 and edgeLean == "r":  # If negative and ray is going down
				return
			if m1 > 0 and edgeLean == "l":  # If positive and ray is going down
				return
	else:
		m1 = 1000000000.0# The more zeros the more accurate as it is a vertical line
	
	if midpoint[1] < size[2]:	# If the edge is a root edge   #1 A root end is a edge that is below the floor
		var mp : Vector2 = midpoint(left_site, right_site)
		b1 = mp[1] - m1*mp[0]
		midpoint = Vector2( (size[2]-b1)/m1, size[2] )
	
	else:
		if midpoint[0] < size[0] or midpoint[0] > size[1]:   # If the starting point is out of bounds #1 left and right walls
			return
		
		b1 = float(midpoint[1] - m1*midpoint[0])
	
	var endPoint : Vector2	#godot specific
	if edgeLean == "l":
		endPoint = Vector2(size[0], m1*size[0] + b1)   # Collision with left boundary #1 colliding with x = self.size[0]
		
		if endPoint[1] > size[3]:    # If outside of the boundary
			endPoint = Vector2( (size[3]-b1)/m1, size[3] )    # Ceiling Collision
		elif endPoint[1] < size[2]: # If negative
			endPoint = Vector2( (size[2]-b1)/m1, size[2] )   # Floor Collision
		
	else:   # edgeLean is right
		endPoint = Vector2( size[1], m1*size[1] + b1 )   #collision with right boundary
		
		if endPoint[1] > size[3]:    # If outside of the boundary
			endPoint = Vector2( (size[3]-b1)/m1, size[3] )    # Ceiling Collision
		elif endPoint[1] < size[2]: #if negative
			endPoint = Vector2( (size[2]-b1)/m1, size[2] )   # Floor Collision
	
	var edge : Array[Vector2] = [midpoint, endPoint]
	#print("Edge: ", edge)
	
	# Close the edges and add them to their respective edge list
	cells[left_site][0].append(edge)
	cells[right_site][0].append(edge)
	
	# Send each cell their respective neighbors
	cells[left_site][1].append(right_site)
	cells[right_site][1].append(left_site)


func removeArc(siteIdx : int) -> void:
	var siteLstIdx : int = self.siteLst.find(siteIdx)
	var beachSiteIdx : int = siteLstIdx * 2
	var site : Vector2 = beachline[beachSiteIdx]    # I need to grab the correct site
	#print("Removing: ", site)
	var left_site : Vector2 = beachline[beachSiteIdx-2]
	var right_site : Vector2= beachline[beachSiteIdx+2]
	
	if left_site == right_site:
		return
	
	var siteId : int = siteLst[siteLstIdx]
	var lSiteId : int = siteLst[siteLstIdx-1]
	var rSiteId : int = siteLst[siteLstIdx+1]
	
	var idxs_for_deletion : Array[int] = []
	for eventIdx in range(len(eventQueue.queue)):
		var e : event = eventQueue.queue[eventIdx]
		if (e.type == 1) and ( e.siteIdx == lSiteId or e.siteIdx == rSiteId or e.siteIdx == siteId):   # FLAG FIX | I do not know I fixed it
			idxs_for_deletion.append(eventIdx)
	
	if idxs_for_deletion != []:
		idxs_for_deletion.reverse()
		for i in idxs_for_deletion:
			eventQueue.queue.remove_at(i)
	idxs_for_deletion = []  # Clear for later use in wall collisions
	
	# Slope 1 x and y
	var s1x : float = float(site[1]-left_site[1])
	var s1y : float = float(-(site[0]-left_site[0]))    # Has to be negative for the creation of a perpendicular slope

	# Slope 2 x and y
	var s2x : float = float(right_site[1]-site[1])
	var s2y : float = float(-(right_site[0]-site[0]))    # Has to be negative for the creation of a perpendicular slope

	# Get the first perpendicular equation
	var midpoint1 : Vector2 = midpoint(site, left_site)
	var m1 : float	#godot specific
	if s1x != 0:
		m1 = float(s1y/s1x)
	else:
		m1 = 1000000000.0# The more zeros the more accurate as it is a vertical line
	var b1 : float = float(midpoint1[1] - m1*midpoint1[0])

	# Get the second perpendicular equation
	var midpoint2 : Vector2 = midpoint(site, right_site)
	var m2 : float # godot specific
	if s2x != 0:
		m2 = float(s2y/s2x)
	else:
		m2 = 1000000000.0# The more zeros the more accurate as it is a vertical line
	var b2 : float = float(midpoint2[1] - m2*midpoint2[0])
	
	var x : float = float((b1-b2)/(m2-m1))
	var circumcenter : Vector2 = Vector2(x, m1*x+b1)    # y = mx + b | The intersection point between the two equations.
	#print("Circumcenter: ", circumcenter)
	
	#1 Floor collision handling of non existant edges
	if circumcenter[1] > size[2]:
		if beachline[beachSiteIdx-1][1] < size[2] and beachline[beachSiteIdx-1] != Vector2(-2,-2):
			beachline[beachSiteIdx-1] = Vector2( (size[2]-b1)/m1, size[2] )   # Floor Collision
		if beachline[beachSiteIdx+1][1] < size[2] and beachline[beachSiteIdx+1] != Vector2(-2,-2): 
			beachline[beachSiteIdx+1] = Vector2( (size[2]-b2)/m2, size[2] )   # Floor Collision
	
	var pos : int = beachSiteIdx - 1
	var edgePos = floor(pos/2.0)
	
	var left_edge : Array[Vector2]	#godot specific
	var right_edge : Array[Vector2]	#godot specific
	
	if circumcenter[0] < size[0]: # Left boundary
		left_edge = [beachline[beachSiteIdx-1], Vector2( size[0], m1*size[0] + b1)]
		right_edge = [beachline[beachSiteIdx+1], Vector2( size[0], m2*size[0] + b2)]
		
		# If there is a ceiling collision then the program is completed and there is no need to compute the rest
		if left_edge[1][1] > size[3] or left_edge[1][1] < size[2]:     # Ceiling/floor collision
			return
		
		if right_edge[1][1] > size[3] or right_edge[1][1] < size[2]:    # Ceiling/floor collision
			return
		
		# Find the border site to be removed(the site that is the end/start of the beachline)
		var beachline_len : int = beachline.size()
		var site_id_lst_for_del : Array[int] = []
		if not beachSiteIdx-2 == 0 and not beachSiteIdx+2 == beachline_len-1:
			# Delete the leftmost sites, and edges from the beachline, until the values to be removed are reached
			for i : int in range(floor(pos/2.0)):
				closeEdge(1)
				# delete_edge_pos = 0
				beachline.remove_at(0)	# Delete Site
				beachline.remove_at(0)	# Delete Edge
				site_id_lst_for_del.append(siteLst.pop_at(0))  # Remove the site's id
				leans.remove_at(0) # Remove the edge's lean
			
			beachline.remove_at(0) # SITE
			beachline.remove_at(0) # EDGE
			beachline.remove_at(0) # SITE
			beachline.remove_at(0) # EDGE
			site_id_lst_for_del.append(siteLst.pop_at(0))   # Remove site from sitelst. variable pos starts from the edge idx
			site_id_lst_for_del.append(siteLst.pop_at(0))   # Remove site from sitelst. variable pos starts from the edge idx
			leans.remove_at(0) # Remove first edge from leans
			leans.remove_at(0) # Remove second edge from leans
			
			pos = 0    # The deletions operated till pos == 0
		else:
			if beachSiteIdx-2 == 0:
				# Delete the leftmost site
				beachline.remove_at(beachSiteIdx-2)   # Site
				edgePos = floor((beachSiteIdx-2)/2.0)
				siteLst.remove_at(edgePos)
				pos -= 1
			elif beachSiteIdx+2 == len(beachline)-1:
				# Delete the rightmost site
				beachline.remove_at(beachSiteIdx+2)   # Site
				edgePos = floor((beachSiteIdx+2)/2.0)
				siteLst.remove_at(edgePos)# Lower the pos because the entire beachline has shifted left by 1
			
			beachline.remove_at(pos) # EDGE
			beachline.remove_at(pos) # SITE
			beachline.remove_at(pos) # EDGE
			siteLst.remove_at(floor(beachSiteIdx/2.0))   # Remove site from sitelst. variable pos starts from the edge idx
			edgePos = floor(pos/2.0)
			leans.remove_at(edgePos) # Remove first edge from leans
			leans.remove_at(edgePos) # Remove second edge from leans
		
		# Remove any events that include the deleted sites
		for eventIdx in range(len(eventQueue.queue)):
			var e : event = eventQueue.queue[eventIdx]
			if (e.type == 1) and (e.siteIdx in site_id_lst_for_del):   # FLAG FIX | I do not know I fixed it
				idxs_for_deletion.append(eventIdx)
			
		if idxs_for_deletion != []:
			idxs_for_deletion.reverse()
			for i in idxs_for_deletion:
				eventQueue.queue.remove_at(i)
		
	
	elif circumcenter[0] > size[1]:    # Right boundary
		#print("Right Intersection")
		left_edge = [beachline[beachSiteIdx-1], Vector2( size[1], m1*size[1] + b1) ]
		right_edge = [beachline[beachSiteIdx+1], Vector2( size[1], m2*size[1] + b2) ]
		
		# If there is a ceiling collision then the program is completed and there is no need to compute the rest
		if left_edge[1][1] > size[3] or left_edge[1][1] < size[2]:     # Ceiling/floor collision
			return

		if right_edge[1][1] > size[3] or right_edge[1][1] < size[2]:    # Ceiling/floor collision
			return
		
		# Find the border site to be removed(the site that is the end/start of the beachline)
		var beachline_len : int = beachline.size()
		var site_id_lst_for_del : Array[int] = []
		if not beachSiteIdx-2 == 0 and not beachSiteIdx+2 == beachline_len-1:
			# Delete the rightmost sites, and edges from the beachline, until the values to be removed are reached
			for i : int in range(beachline_len-2, pos+2, -2):
				closeEdge(i)
				var delete_edge_pos : int = floor(i/2.0)
				beachline.remove_at(i)   # Delete Edge
				beachline.remove_at(i)   # Delete Site
				site_id_lst_for_del.append(siteLst.pop_at(delete_edge_pos))  # Remove the site's id
				leans.remove_at(delete_edge_pos) # Remove the edge's lean
			
			beachline.remove_at(pos) # SITE
			beachline.remove_at(pos) # EDGE
			beachline.remove_at(pos) # SITE
			beachline.remove_at(pos) # EDGE
			site_id_lst_for_del.append(siteLst.pop_at(floor(beachSiteIdx/2.0)))   # Remove site from sitelst. variable pos starts from the edge idx
			site_id_lst_for_del.append(siteLst.pop_at(floor(beachSiteIdx/2.0)))   # Remove site from sitelst. variable pos starts from the edge idx
			edgePos = floor(pos/2.0)
			leans.remove_at(edgePos) # Remove first edge from leans
			leans.remove_at(edgePos) # Remove second edge from leans
		
		else:
			if beachSiteIdx-2 == 0:
				# Delete the leftmost site
				beachline.remove_at(beachSiteIdx-2)   # Site
				edgePos = floor((beachSiteIdx-2)/2.0)
				siteLst.remove_at(edgePos)
				pos -= 1
			elif beachSiteIdx+2 == len(beachline)-1:
				# Delete the rightmost site
				beachline.remove_at(beachSiteIdx+2)   # Site
				edgePos = floor((beachSiteIdx+2)/2.0)
				siteLst.remove_at(edgePos)# Lower the pos because the entire beachline has shifted left by 1
			
			beachline.remove_at(pos) # EDGE
			beachline.remove_at(pos) # SITE
			beachline.remove_at(pos) # EDGE
			site_id_lst_for_del.append(siteLst.pop_at(floor( beachSiteIdx/2.0) ))   # Remove site from sitelst. variable pos starts from the edge idx
			edgePos = floor(pos/2.0)
			leans.remove_at(edgePos) # Remove first edge from leans
			leans.remove_at(edgePos) # Remove second edge from leans
		
		# Remove any events that include the deleted sites
		for eventIdx in range(len(eventQueue.queue)):
			var e : event = eventQueue.queue[eventIdx]
			if (e.type == 1) and (e.siteIdx in site_id_lst_for_del):   # FLAG FIX | I do not know I fixed it
				idxs_for_deletion.append(eventIdx)
			
		if idxs_for_deletion != []:
			idxs_for_deletion.reverse()
			for i in idxs_for_deletion:
				eventQueue.queue.remove_at(i)
		
		
	elif circumcenter[1] >= size[3] :#or circumcenter[1] < 0:    # Ceiling/floor collision. I decided to add this on instead of editing for now until I can do more testing
		#print("Ceiling limit passed")
		return
	elif circumcenter[1] < size[2]:   # Floor collision
		###NOTICE###
		# This edge case fix assumes that the collision is occuring between two roots and 1 non-root point that caused the intersection. The point is also between the two root points <- The last sentence may not be nessasary. I think it's nessasary
		# This is a special case where there is a second intersection in a row underneath the floor(y=0)
		# It is check if both sides of the edge is unknown(below the the floor)
		#print("floor limit passed")
		var center_site : Vector2
		left_edge = []
		right_edge = []
		
		var lFloorPnt : Vector2	# Godot specific
		var rFloorPnt : Vector2	# Godot specific
		# If the left and right half edges are defined (above the beachline)
		if site not in root and beachline[beachSiteIdx-1][1] > size[2] and beachline[beachSiteIdx+1][1] > size[2]:
			left_edge = [beachline[beachSiteIdx-1], Vector2((size[2]-b1)/m1, size[2])]
			right_edge = [beachline[beachSiteIdx+1], Vector2((size[2]-b2)/m2, size[2])]
			var floor_edge : Array[Vector2] = [right_edge[1], left_edge[1]]
			
			# Add the edges to their respective edge list
			cells[left_site][0].append(left_edge)
			cells[right_site][0].append(right_edge)
			cells[site][0].append_array([left_edge, floor_edge, right_edge])
			
			# Send each cell their respective neighbors
			cells[left_site][1].append(site)
			cells[right_site][1].append(site)
			cells[site][1].append_array([left_site, right_site])
		
		# If the left and right half edges are under the beachline
		elif site in root and beachline[beachSiteIdx-1][1] < size[2] and beachline[beachSiteIdx+1][1] < size[2]:
			pass
		
		# If the right half edge has a non-root edge then close it
		elif beachline[beachSiteIdx+1][1] > size[2]:
			#print("Left site")
			# The right site is the non-root site
			center_site = right_site
			# Generate perpendicular equation between left and right sites for the left site collision
			# Slope 1 x and y
			s1x = float((center_site[1]-left_site[1]))
			s1y = float(-(center_site[0]-left_site[0]))    # Has to be negative for the creation of a perpendicular slope
			# Get the first perpendicular equation
			midpoint1 = midpoint(center_site, left_site)
			if s1x != 0:
				m1 = float(s1y/s1x)
			else:
				m1 = 1000000000.0# The more zeros the more accurate as it is a vertical line
			b1 = float(midpoint1[1] - m1*midpoint1[0])
			lFloorPnt = Vector2( (size[2]-b1)/m1, size[2] )   # Floor Collision
			rFloorPnt = Vector2( (size[2]-b2)/m2, size[2] )   # Site and right_site floor Collision
			
			left_edge = [lFloorPnt, rFloorPnt]
			right_edge = [beachline[beachSiteIdx+1], rFloorPnt]
			
			# Add the edges to their respective edge list
			cells[site][0].append(right_edge)
			cells[center_site][0].append(right_edge)
			
			# Send each cell their respective neighbors
			cells[site][1].append(center_site)
			cells[center_site][1].append(site)
		
		# If the left half edge has a non-root edge then close it
		elif beachline[beachSiteIdx-1][1] > size[2]:
			#print("Right site")
			# The left site is the non-root site
			center_site = left_site
			# Generate perpendicular equation between left and right sites for the left site collision
			# Slope 1 x and y
			s2x = float(right_site[1]-center_site[1])
			s2y = float(-(right_site[0]-center_site[0]))    # Has to be negative for the creation of a perpendicular slope
			# Get the first perpendicular equation
			midpoint2 = midpoint(right_site, center_site)
			if s2x != 0:
				m2 = float(s2y/s2x)
			else:
				m2 = 1000000000.0# The more zeros the more accurate as it is a vertical line
			b2 = float(midpoint2[1] - m2*midpoint2[0])
			lFloorPnt = Vector2( (size[2]-b1)/m1, size[2] )   # Floor Collision
			rFloorPnt = Vector2( (size[2]-b2)/m2, size[2] )   # Site and right_site floor Collision
			
			left_edge = [beachline[beachSiteIdx-1], lFloorPnt]
			right_edge = [lFloorPnt, rFloorPnt]
			
			# Add the edges to their respective edge list
			cells[site][0].append(left_edge)
			cells[center_site][0].append(left_edge)
			# Send each cell their respective neighbors
			cells[site][1].append(center_site)
			cells[center_site][1].append(site)
		
		#print("Continued")
		# Copied from code block below. The only change was the lFloor and rFloor variables
		# Replace old edges and site with new edge
		beachline.remove_at(pos) #EDGE
		beachline.remove_at(pos) #SITE
		beachline.remove_at(pos) #EDGE
		siteLst.erase(siteIdx)  # The edge pos is moved left by one for deleting the edges and can't be used to delete the site lst
		
		# Remove old edge's directions while storing them to calculate the new edge's lean
		var lEdgeDir : String = leans.pop_at(edgePos)
		var rEdgeDir : String = leans.pop_at(edgePos)
		# Create the new edge
		beachline = extendAtIndex(beachline, [circumcenter], pos)
		
		# Calculate lean of edge based on last edges
		if lEdgeDir == rEdgeDir:    #like: r facing edge + right facing edge = right facing edge. Vise versa for left
			leans = extendAtIndex(leans ,[lEdgeDir], edgePos)
		else:
			# Find the direction based on the highest point
			if beachline[beachSiteIdx-2][1] < beachline[beachSiteIdx][1]: # Right greater than left
				leans = extendAtIndex(leans, ["l"], edgePos)
			else:   # Left greater than right
				leans = extendAtIndex(leans, ["r"], edgePos)
		
		CheckCircleEvent(beachSiteIdx-2)    # Index of left site
		CheckCircleEvent(beachSiteIdx)      # Index of right site
		return
	else:   # No boundary was collided with
		left_edge = [beachline[beachSiteIdx-1], circumcenter]
		right_edge = [beachline[beachSiteIdx+1], circumcenter]
		
		# Replace old edges and site with new edge
		beachline.remove_at(pos) # EDGE
		beachline.remove_at(pos) # SITE
		beachline.remove_at(pos) # EDGE
		siteLst.erase(siteIdx)  # The edge pos is moved left by one for deleting the edges and can't be used to delete the site lst
		
		# Remove old edge's directions while storing them to calculate the new edge's lean
		var lEdgeDir : String = leans.pop_at(edgePos)
		var rEdgeDir : String = leans.pop_at(edgePos)
		
		# Create the new edge
		beachline = extendAtIndex(beachline, [circumcenter], pos)
		
		# Calculate lean of edge based on last edges
		if lEdgeDir == rEdgeDir and (lEdgeDir != "idk" and rEdgeDir != "idk"):    # like: r facing edge + right facing edge = right facing edge. Vise versa for left
			leans = extendAtIndex(leans ,[lEdgeDir], edgePos)
		else:
			# Find the direction based on the highest point
			if beachline[beachSiteIdx-2][1] < beachline[beachSiteIdx][1]: # Right greater than left
				leans = extendAtIndex(leans, ["l"], edgePos)
			else:   # Left greater than right
				leans = extendAtIndex(leans, ["r"], edgePos)
		
		CheckCircleEvent(beachSiteIdx-2)    # Index of left site
		CheckCircleEvent(beachSiteIdx)      # Index of right site
	
	# Add the edges to their respective edge list
	cells[left_site][0].append(left_edge)
	cells[right_site][0].append(right_edge)
	cells[site][0].append_array([left_edge, right_edge])
	
	# Send each cell their respective neighbors
	cells[left_site][1].append(site)
	cells[right_site][1].append(site)
	cells[site][1].append_array([left_site, right_site])
	
	#print("Remove Arc")

var root : Array[Vector2]= []  # Contains every edge that is collides with the borderline/floor
var beachline : Array = []   # Beachline in form [site0, edge0, site1, edge1]
var leans : Array[String]= [] # Contains the direction for every edge ( l = left, r = right)
var siteLst : Array[int] = []   # List of non-repeating interger ids for every site, allowing calling of the correct site
var siteCounter : int    # A integer counter that only increases. Is used for setting ids to all of the points. Allows for no duplication
var sweepline : float
var eventQueue : PriorityQueue
func generate() -> void:
	root = []
	beachline = []
	leans = []
	siteLst = []
	siteCounter = 0
	sweepline = 0
	eventQueue = PriorityQueue.new()

	# Set all of the sites as site events in the queue
	for point in pointLst:
		eventQueue.queue.append(event.new(-1, 0, point[1], point))
	#print("------------------")
	#print("Size: ", size)
	#print("------------------")
	while ( len(eventQueue.queue) > 0):  # Run while the event queue is not empty
		#print("======================================")
		#print("Beachline before: ", beachline)
		var nextEvent : event = eventQueue.pop()
		sweepline = nextEvent.priority
		#print("Sweepline: ", sweepline)
		if nextEvent.type == 0:
			# Site event
			# Add to beachline
			addArc(nextEvent.site)
		else:
			# It is a circle event
			# Remove from beachline
			removeArc(nextEvent.siteIdx)
		
		#print("Beachline after: ", beachline)
	
	# Close final edges
	for edgeIdx : int in range(1,beachline.size(), 2):
		#print(edgeIdx)
		if leans[floor(edgeIdx/2.0)] != "DNE":
			closeEdge(edgeIdx)
	
	# Turn all edgelist into polygons!
	for cell_name : Vector2 in cells:
		#print(str(cell_name) + " | Edges | ", cells[cell_name][0])
		orderEdges(cell_name)
	
	# Add the corner point
	var cornerLst : PackedVector2Array = PackedVector2Array([
		Vector2(size[0], size[2]),	# Bottom left
		Vector2(size[0], size[3]),	# Top left
		Vector2(size[1], size[2]),	# Bottom right
		Vector2(size[1], size[3])	# Top right
	])
	
	for corner : Vector2 in cornerLst:
		var cell_name : Vector2 = nearest_point(corner)
		if cells[cell_name][0][0][0] == corner[0] or cells[cell_name][0][0][1] == corner[1]:  # If the x's or y's are the same
			if corner not in cells[cell_name][0]:
				cells[cell_name][0].insert(0, corner)  # The corner may already be in the polygon
		else:
			if corner not in cells[cell_name][0]:
				cells[cell_name][0].append(corner)     # The corner may already be in the polygon
