using Godot;
using System;
using System.Collections.Generic;
using System.Linq;


public partial class Volornoi : Node2D
{
	List<Site> sites = new List<Site>{};
	public Dictionary<string, Cell> Cells = new Dictionary<string, Cell>{};
	List<double> size;

	//init function to run code
	public void init(Godot.Collections.Array<double> plane_size) {	//boundaries are set as [x,y]
		//List<List<double>> points = new List<List<double>> {new List<double> {2,2}, new List<double> {1,1}, new List<double> {3,3}, new List<double> {1,3},new List<double> {3,1}};
		size = plane_size.ToList();
		//Test.update(points.ToList());
	}

	static private List<List<double>> godotToC(Godot.Collections.Array<Godot.Collections.Array<double>> Inarr) {	//convert 2d godot array to 2d list
		List<List<double>> Outarr = new List<List<double>> {};
		foreach(Godot.Collections.Array<double> arr in Inarr) {
			Outarr.Add(arr.ToList());
		}

		return Outarr;
	}
	public Godot.Collections.Dictionary update(Godot.Collections.Array<Godot.Collections.Array<double>> In_sites) {
		//sort size by y lowest to highest
		List<List<double>> Loc_In_sites = Volornoi.godotToC(In_sites);	//convert godot array to c# array
		Loc_In_sites = Loc_In_sites.OrderBy(x => x[1]).ToList();
		
		foreach (List<double> pos in Loc_In_sites)
		{
			sites.Add(new Site(pos));
			Cells[String.Join(",", pos.Select(p=>p.ToString()).ToArray())] = new Cell(pos);     //--String Conversion Bookmark
		}
		
		generate();
		
		
		//GD.Print(Cells);
		//dictionarys to return
		var outDict = new Godot.Collections.Dictionary();
		foreach(var Cell in Cells) {
			var valueArr = new Godot.Collections.Array();
			valueArr.Add(Cell.Value.getPolygon());
			//convert neighbors list to godot Array
			var neighborArr = new Godot.Collections.Array();
			foreach(var neighbor in Cell.Value.neighbors) {
				neighborArr.Add( new Vector2(Convert.ToSingle(neighbor[0]), Convert.ToSingle(neighbor[1])) );
			}
			valueArr.Add(neighborArr);
			outDict.Add(new Vector2(Convert.ToSingle(Cell.Value.site[0]), Convert.ToSingle(Cell.Value.site[1])), valueArr);	//convert the cell with their polygons to godot dictionary
		}
		
		return outDict;
	}


	public void generate() {
		//add corner flags to sites
		Cells[String.Join(",", Volornoi.find_closest(new List<double> {0, size[1]}, sites).pos.Select(p=>p.ToString()).ToArray())].corner = "l";	//left corner flag
		Cells[String.Join(",", Volornoi.find_closest(size, sites).pos.Select(p=>p.ToString()).ToArray())].corner = "r";	//right corner flag

		List<double> x_vals = new List<double>{};
		double end = size[1] * 2;	//makes sute that all of the points have been traced off screen
		int site_index = 0;	//I have to preset the next site value
		//There are 4 seperate starting equations. Each one is a boundary
		List<Site> beach_line = new List<Site> {
						new Site(new List<double> {-1,-1}, true, new double[] {0,size[1]}),
		};
		Site next_site = sites[site_index];
		double sweepline = next_site[1];	//moves vertically up
		int sweep_check = 0;	//an interger value that counts the amount of loops for every time the sweepline has not met the crieteria to stay at it's current speed
		List<double> sweepline_speed_vals = new List<double> {.00001, .001, .01};
		double sweepline_speed = sweepline_speed_vals[0];
		bool special = false;	//the special flag is for the edge case of the new site being right on one of the x_vals; which splits the one half edge into two, each involving the new site
		List<HalfEdge> half_edges = new List<HalfEdge>{};
		bool newsitesAvailiable = true;		//flag to prevent extra comparisons
		while (sweepline < end) {
			
			//////site ADDITION EVENT////////
			//if sweepline reaches the next site: add site and new half edge
			if (newsitesAvailiable && next_site[1] <= sweepline) {
				beach_line.Add(next_site);
				
				var (half_edges_out, sp) = intersect(beach_line, next_site, x_vals, half_edges);

				half_edges = half_edges_out;
				if (sp && !special) {
					special = true;
				}
				sweepline_speed = sweepline_speed_vals[0];
				sweep_check = 1;	//reset the counter
				if (site_index < sites.Count-1) {
					site_index += 1;
					next_site = sites[site_index];
				} else {
					newsitesAvailiable = false;
					next_site = new Site(new List<double>{0, 9999999999999999}); // value that has no chance of being reached
				}
			//////CHECK FOR site INTERSECTION//////
			} else {
				if (special) {
					//pushes the sweepline forward to avoid intersection betweeen any newly created half edges
					sweepline += .003;
					special = false;
				}
				List<HalfEdge> new_edges = new List<HalfEdge>{};
				List<HalfEdge> rem_edges = new List<HalfEdge>{};
				//calculate all x values and check for duplicates
				x_vals.Clear();
				foreach (HalfEdge half_edge in half_edges) {
					
						
					List<double> result = half_edge.update(sweepline).ToList();
					//if result:
					x_vals.AddRange(result);

					//GD.Print(new Godot.Collections.Array<double>(half_edge.site1.pos));
				}

				//if there are duplicates then there is an intersection
				List<List<double>> x_dups = Volornoi.duplicates(x_vals, .002);
				//sweepline control section
				
				if (x_dups.Count() > 0 || Volornoi.duplicates(x_vals, .05).Any()) {
					sweepline_speed = sweepline_speed_vals[0];
				} else if (sweep_check > 100) {
					sweepline_speed = sweepline_speed_vals[1];
				} else {
					sweep_check += 1;
				}
				//////site INTERSECTION EVENT
				foreach (List<double> dup in x_dups) {
					//I don't understand Math.Floor so...
					int index0 = x_vals.FindIndex(a => a == dup[0])/2;
					int index1 = x_vals.FindIndex(a => a == dup[1])/2;
					if (index0 != index1) {
						//retrieves each half edge to get the sites
						HalfEdge half_edge1 = half_edges[index0];
						HalfEdge half_edge2 = half_edges[index1];
						
						//Console.WriteLine("Normal Intersection");
						//Console.WriteLine("Sweepline: {0}", sweepline);
						//Console.WriteLine($"Half Edge using sites: [{half_edge1.site1.pos[0]}, {half_edge1.site1.pos[1]}] and [{half_edge1.site2.pos[0]}, {half_edge1.site2.pos[1]}]");
						//Console.WriteLine($"Half Edge using sites: [{half_edge2.site1.pos[0]}, {half_edge2.site1.pos[1]}] and [{half_edge2.site2.pos[0]}, {half_edge2.site2.pos[1]}]");

						List<Site> lst = new List<Site> {half_edge1.site1, half_edge1.site2, half_edge2.site1, half_edge2.site2};
						
						
						Site sim_site = new Site( new List<double> {-1,-1});
						
						foreach (Site c_site in lst) {
							int i = 0;
							foreach(Site t_site in lst) {
								if(c_site.pos.SequenceEqual(t_site.pos)) {
									i++;
								}
							}
							if (i == 2) {
								sim_site = c_site;
								break;
							}
						}
						
						/*site sim_site = lst.GroupBy(x => x)
						.Where(g => g.Count() > 1)
						.Select(x => x.Key).ToList()[0];*/

						//create a new edge of the two collided polynomials with the start point the collision
						lst.RemoveAll(item => item == sim_site);

						//get the highest y value point first to avoid accidental boundary point calculation (-1,-1)
						if (lst[0][1] < lst[1][1]) {
							lst.Reverse();
						}
						List<double> intersection_point = new List<double> {dup[0], (Math.Pow(dup[0]-lst[0][0],2)/(2*(lst[0][1]-sweepline)))+((lst[0][1]+sweepline)/2)};

						bool result = half_edge1.setPoint(intersection_point, sweepline);
						if (result == true) {
							Cells[String.Join(",", half_edge1.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
							if (half_edge1.site2.boundary == false){
								Cells[String.Join(",", half_edge1.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
							}
							rem_edges.Add(half_edge1);
						}
						
						result = half_edge2.setPoint(intersection_point, sweepline);
						if (result == true) {
							Cells[String.Join(",", half_edge2.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge2);
							if (half_edge2.site2.boundary == false){
								Cells[String.Join(",", half_edge2.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge2);
							}
							rem_edges.Add(half_edge2);
						}
						sweepline_speed = sweepline_speed_vals[0];
						HalfEdge new_half_edge = new HalfEdge(lst[0], lst[1], intersection_point);
						//edge case if all the points are on one side of the intersection point
						if (lst[0][0] < intersection_point[0] && lst[1][0] < intersection_point[0] && sim_site[0] < intersection_point[0]) {
							new_half_edge.lean = "r";
						}
						else if (lst[0][0] > intersection_point[0] && lst[1][0] > intersection_point[0] &&  sim_site[0] > intersection_point[0]) { //lst[1].boundary:
							new_half_edge.lean = "l";
						}
						
						new_edges.Add(new_half_edge);
						//Console.WriteLine($"New Half Edge using sites: [{new_half_edge.site1.pos[0]}, {new_half_edge.site1.pos[1]}] and [{new_half_edge.site2.pos[0]}, {new_half_edge.site2.pos[1]}] | lean: {new_half_edge.lean}");
						//Console.WriteLine("----------------------");
					}
				}
				//////BORDER INTERSECT//////
				foreach (double x in x_vals){ 
					if (x != -1 && x < 0) {	//.001 is the margin of error	|	Check to see if the x axis 0 is intersected
						int index = x_vals.FindIndex(a => a == x)/2;
						HalfEdge half_edge1 = half_edges[index];
						List<double> intersection_point = new List<double> {0, (Math.Pow(0-half_edge1.site1[0],2)/(2*(half_edge1.site1[1]-sweepline)))+((half_edge1.site1[1]+sweepline)/2)};
						bool result = half_edge1.setPoint(intersection_point, sweepline);
						if (result == true) {
							Cells[String.Join(",", half_edge1.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
							if (half_edge1.site2.boundary == false){
								Cells[String.Join(",", half_edge1.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
							}
							rem_edges.Add(half_edge1);
						} else {
							half_edge1.lean = "r";
						}
						//Console.WriteLine("Left Border Intersection");
						//Console.WriteLine("Sweepline: {0}", sweepline);
						//Console.WriteLine($"Half Edge using sites: [{half_edge1.site1.pos[0]}, {half_edge1.site1.pos[1]}] and [{half_edge1.site2.pos[0]}, {half_edge1.site2.pos[1]}]");
						//Console.WriteLine("----------------------");

					}	
					if (x > size[0]){	//check to see of the x boundary is intersected
						int index = x_vals.FindIndex(a => a == x)/2;
						HalfEdge half_edge1 = half_edges[index];
						List<double> intersection_point = new List<double> {size[0], (Math.Pow(size[0]-half_edge1.site1[0], 2)/(2*(half_edge1.site1[1]-sweepline)))+((half_edge1.site1[1]+sweepline)/2)};
						bool result = half_edge1.setPoint(intersection_point, sweepline);
						if (result == true) {
							Cells[String.Join(",", half_edge1.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
							if (half_edge1.site2.boundary == false){
								Cells[String.Join(",", half_edge1.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
							}
							rem_edges.Add(half_edge1);
						} else {
							half_edge1.lean = "l";
						}
						//Console.WriteLine("Right Border Intersection");
						//Console.WriteLine("Sweepline: {0}", sweepline);
						//Console.WriteLine($"Half Edge using sites: [{half_edge1.site1.pos[0]}, {half_edge1.site1.pos[1]}] and [{half_edge1.site2.pos[0]}, {half_edge1.site2.pos[1]}]");
						//Console.WriteLine("----------------------");
					}
					//check for top boundary collision after final site is added
					if (!newsitesAvailiable) {
						int index = x_vals.FindIndex(a => a == x)/2;
						HalfEdge half_edge1 = half_edges[index];
						if (!rem_edges.Contains(half_edge1)) {
							double y = (Math.Pow((x-half_edge1.site1[0]),2))/(2*(half_edge1.site1[1]-sweepline)) + (half_edge1.site1[1]+sweepline)/2;
							if (x != -1 && y > size[1]) {	//-1 is the NAN number. 
								List<double> intersection_point = new List<double> {x, size[1]};
								bool result = half_edge1.setPoint(intersection_point, sweepline);
								if (result == true) {
									Cells[String.Join(",", half_edge1.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
									if (half_edge1.site2.boundary == false){
										Cells[String.Join(",", half_edge1.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
									}
									rem_edges.Add(half_edge1);
								}
							}
						}
					}
				}

				//////EDIT HALF EDGES
				foreach(HalfEdge edge in rem_edges) {
					half_edges.Remove(edge);
				}
				if (new_edges.Any()) {
					half_edges.AddRange(new_edges);
				}
				if (newsitesAvailiable == false && half_edges.Count() == 0) {
					break;
				}
			}
			//Console.WriteLine("Sweepline: {0}", sweepline);
			sweepline += sweepline_speed;
		}

		//// CLOSE FINAL EDGES ////
		foreach(HalfEdge edge in half_edges) {
			double[] x_intersect = Volornoi.site_intersect(edge.site1, edge.site2, end, edge.lean);
			List<double> intersection_point;
			if (edge.lean == "l") {
				intersection_point = new List<double> {x_intersect[0], ((Math.Pow((x_intersect[0]-edge.site1[0]),2))/(2*(edge.site1[1]-end)))+((edge.site1[1]+end)/2)};
			} else {
				intersection_point = new List<double> {x_intersect[1], ((Math.Pow((x_intersect[1]-edge.site1[0]),2))/(2*(edge.site1[1]-end)))+((edge.site1[1]+end)/2)};
			}
			//create a point slope equation to find the point that intersects the ceiling
			//y=mx+b
			double m = (intersection_point[1]-edge.startPoint[1])/(intersection_point[0]-edge.startPoint[0]);
			double b = (m*-edge.startPoint[0])+edge.startPoint[1];
			//Console.WriteLine("Y = " + m.ToString() + " + " + b.ToString());
			intersection_point = new List<double> {(size[1]-b)/m, size[1]};
			//Console.WriteLine(intersection_point[0]);
			//Console.WriteLine(intersection_point[1]);
			edge.setPoint(intersection_point);
			Cells[String.Join(",", edge.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(edge);
			if(edge.site2.boundary == false) {
				Cells[String.Join(",", edge.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(edge);
			}
		}

		foreach(var Cell in Cells) {
			Cell.Value.orderEdges(size);

			//GD.Print(Cell.Value.getPolygon());
			
		}
		
	}
	//only called when new site is reached
	private Tuple< List<HalfEdge>, bool> intersect(List<Site> beach_line, Site target_site, List<double> x_vals, List<HalfEdge>half_edges)
	{			
		bool special = false;	//explantation for variable givin near start of the 'create' function
		//.002 is the margin of error due to floating point calculations
		List<double> x_val_intersection = new List<double>{};
		foreach (double x in x_vals) {
			if (Math.Abs(x-target_site[0]) < .002) {    //<--- Probable VSCode mishap
				x_val_intersection.Add(x);
			}
		}

		if (x_val_intersection.Any()) {
			int index = x_vals.FindIndex(a => a == x_val_intersection[0])/2;
			HalfEdge half_edge1 = half_edges[index];      
			List<double> intersection_point = new List<double> { target_site[0], (Math.Pow(target_site[0]-half_edge1.site1[0], 2))/(2*(half_edge1.site1[1]-target_site[1])) + (half_edge1.site1[1]+target_site[1])/2 };   //<--- Probable VSCode mishap
			bool result = half_edge1.setPoint(intersection_point);
			if (result == true) {
				Cells[String.Join(",", half_edge1.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
				if (half_edge1.site2.boundary == false){
					Cells[String.Join(",", half_edge1.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
				}

				half_edges.Remove(half_edge1);
			}
			HalfEdge new_half_edge1 = new HalfEdge(target_site, half_edge1.site1, intersection_point);
			HalfEdge new_half_edge2 = new HalfEdge(target_site, half_edge1.site2, intersection_point);
			
			//check to make sure that the correct lean is applied when the x's are the same
			if (target_site[0] == new_half_edge1.site2[0]) {
				if (target_site[0] < new_half_edge2.site2[0]) {	//use the non same x to determine the lean
					new_half_edge1.lean = "l";
				} else {
					new_half_edge1.lean = "r";
				}
			
			}else if (target_site[0] == new_half_edge2.site2[0]){
				if (target_site[0] < new_half_edge1.site2[0]) {
					new_half_edge2.lean = "l";
				} else {
					new_half_edge2.lean = "r";
				}
			}

			if (half_edge1.site2.boundary) {
				if (new_half_edge1.lean == "l"){
					new_half_edge2.lean = "r";
				} else {
					new_half_edge2.lean = "l";
				}
			}
			special = true;

			half_edges.Add(new_half_edge1);
			half_edges.Add(new_half_edge2);
			
			

		} else {
			//check for intersect with any site in the beach line
			double largest_y = 0;
			Site chosen_site = new Site(new List<double> {-1,-1});
			bool root = false;
			foreach (Site site in beach_line) {
				if (site != target_site) {
					//if site is not a border site
					if (site.boundary == false){
						double y = -100000;
						if (target_site[1] != site[1]){
							//calculate the y at the x line that intersects the site
							y = (Math.Pow((target_site[0]-site[0]),2))/(2*(site[1]-target_site[1]))+((target_site[1]+site[1])/2);
						}
						if (y > largest_y) {
							largest_y = y;
							chosen_site = site;
							if (site.root == true) {
								root = true;
							} else {
								root = false;
							}
							target_site.root = false;
						}
					} else {
						//test boundary collisions
						//if the target equ's is above the site's y then there is a collision
						if (target_site[1] > site.boundary_equ[1]) {
							double y = site.boundary_equ[1];
							
							if (y > largest_y) {
								largest_y = y;
								chosen_site = site;
								target_site.root = true;
								root = true;
							}
						}
					}
				}
			}

			//replaces the chosen site with the bottom border if the intersect position of the chosen site is negative
			if (0 >= largest_y) {
				chosen_site = beach_line[0];
				target_site.root = true;
				root = true;
			}
			//incase the point's x is near, but not directly inbetween one of the x_vals
			double dist_between = target_site[1] - largest_y;
			double sweepline = dist_between + .0001;
			double dist_to_check = Math.Sqrt(-((dist_between+sweepline)*(2*(dist_between-sweepline)))/2) + .1;	//the additional .1 is because the main formula is for the EXACT distance between the target's site x and the y line at the highest y
			List<double> x_val_close = new List<double>{};
			foreach (double x in x_vals) {
				if (Math.Abs(x-target_site[0]) < dist_to_check) {
					x_val_close.Add(x);
				}
			}
			if (x_val_close.Any()) {
				int index = x_vals.FindIndex(a => a == x_val_close[0])/2;
				HalfEdge half_edge1 = half_edges[index];
				//push the sweepline by a very small number to allow for the code to calculate the lean
				sweepline = target_site[1] + .00001;
				List<double> intersection_point = new List<double> { x_val_close[0], (Math.Pow((x_val_close[0]-half_edge1.site1[0]),2))/(2*(half_edge1.site1[1]-sweepline)) + (half_edge1.site1[1]+sweepline)/2 };
				bool result = half_edge1.setPoint(intersection_point);
				if (result == true) {
					Cells[String.Join(",", half_edge1.site1.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
					if (half_edge1.site2.boundary == false){
						Cells[String.Join(",", half_edge1.site2.pos.Select(p=>p.ToString()).ToArray())].addEdge(half_edge1);
					}

					half_edges.Remove(half_edge1);
				}
				//create a brand new HalfEdge
				
				HalfEdge new_half_edge1 = new HalfEdge(target_site, chosen_site, root);
				HalfEdge new_half_edge2;
				new_half_edge1.setPoint(intersection_point);
				if (chosen_site == half_edge1.site1) {
					new_half_edge2 = new HalfEdge(target_site, half_edge1.site2, intersection_point, root);
				} else {
					new_half_edge2 = new HalfEdge(target_site, half_edge1.site1, intersection_point, root);
				}
				if (new_half_edge1.lean == "l"){
					new_half_edge2.lean = "r";
				} else {
					new_half_edge2.lean = "l";
				}
				half_edges.Add(new_half_edge1);
				half_edges.Add(new_half_edge2);

			} else{
				HalfEdge new_half_edge = new HalfEdge(target_site, chosen_site, root);
				new_half_edge.lean = "a";	//set to any value as the default value makes it calculate the collision with the floor of y=0
				half_edges.Add(new_half_edge);
			}
			//half_edges.Add(new HalfEdge(target_site, chosen_site, root));
		}



		return Tuple.Create(half_edges, special);
	}

	//returns all NUMERICAL duplicates within the margin of error
	//used to find possible intersections
	static private List<List<double>> duplicates(List<double> arr_in, double margin_of_err){
		List<double> arr = arr_in.ConvertAll(s => s).ToList();  //creates a copy of arguement array do global array isn't edited by sort command
		
		arr.Sort();
		List<List<double>>duplicates = new List<List<double>>{};	//stores all of the duplicate groups
		List<double> duplicate_group = new List<double>{};
		double last_val = -9999999999999999;	// hope noone get a duplicate if this value
		for(int i=0; i < arr.Count - 1; i++){
			if (Math.Abs(arr[i] - arr[i+1]) < margin_of_err && arr[i] >= 0){
				if (last_val != arr[i]){
					duplicate_group.AddRange(new List<double> {arr[i], arr[i+1]});
					last_val = arr[i+1];
				} else {
					duplicate_group.Add(arr[i+1]);
					last_val = arr[i+1];
				}
			} else if (duplicate_group.Any()) {
				duplicates.Add(duplicate_group);
				duplicate_group = new List<double>{};
			}
		}
		if (duplicate_group.Any()){
			duplicates.Add(duplicate_group);
		}
		return duplicates;
	}

	//find the closest point to a site given an array of points 
	static private Site find_closest(List<double> point, List<Site> arr) {
		double largest_dist = 99999999999999;
		Site chosen_site = new Site(new List<double> {-1,-1});

		foreach(Site site in arr) {
			double test_dist = Math.Sqrt(Math.Pow(site[0]-point[0], 2) + Math.Pow(site[1]-point[1], 2));
			if (test_dist < largest_dist){
				largest_dist = test_dist;
				chosen_site = site;
			}
		}
		return chosen_site;
	}




	static public double[] site_intersect(Site site1,Site site2, double sweepline, string lean)
	{
		double[] equ1 = {site1[0], (site1[1]+sweepline)/2, 2*(site1[1]-sweepline)};
		double[] equ2 = {site2[0], (site2[1]+sweepline)/2, 2*(site2[1]-sweepline)};

		double[] poly = {(1/equ1[2])-(1/equ2[2]), ((-equ1[0]*2)/equ1[2])-((-equ2[0]*2)/equ2[2]), (((Math.Pow(equ1[0],2))+(equ1[1]*equ1[2]))/equ1[2])-(((Math.Pow(equ2[0],2))+(equ2[1]*equ2[2]))/equ2[2])};

		if (poly[0] == 0) 
		{
			double[] outVar = {Math.Abs(poly[2]/poly[1]), -1};
			return outVar;
		}

		//calculate the zeros of the polygon
		double discriminant = Math.Sqrt(Math.Pow(poly[1],2) - (4*poly[0]*poly[2]));
		double denominator = 2*poly[0];
		double[] intersections = {(-poly[1]+discriminant)/denominator, (-poly[1]-discriminant)/denominator};

		Array.Sort(intersections);
		if (lean == "r")
		{
			intersections[0] = -1;
		}else if (lean == "l")
		{
			intersections[1] = -1;
		}
		return intersections;
	}
}

public partial class Site
{
	public double[] pos;
	public bool root = false;
	public bool boundary = false;
	public double[] boundary_equ;

	public Site(List<double> position, bool bound=false, double[] bound_equ=null)
	{
		pos = position.ToArray();
		
		//for boundary sites
		boundary = bound;
		if (bound == true)
		{
			boundary_equ = bound_equ;    //boundary_equ[0] is unused | boundary_equ1 could change though
		}
	}
	public double this[int i]
   {
	  get { return pos[i]; }
	  set { pos[i] = value; }
   }
}


public partial class HalfEdge
{
	public List<double> startPoint;
	public List<double> endPoint = new List<double>();
	public Site site1;
	public Site site2;
	public bool root;
	public string lean = "none"; //base value. Only used for the floor
	public HalfEdge(Site s1, Site s2, bool root_param=false)
	{
		site1 = s1;
		site2 = s2;
		root = root_param;
		startPoint = new List<double> {0,0};
	}
	public HalfEdge(Site s1, Site s2, List<double> beginPoint, bool root_param=false)
	{
		site1 = s1;
		site2 = s2;
		root = root_param;
		startPoint = beginPoint;

		if (!beginPoint.SequenceEqual(new List<double> {0,0}))
		{
			if (site1[1] == site2[1]) {
				lean = "l";
			} else if (site1[0] > site2[0] ) {
				//calculate if on left or right side
				lean = "l";
			} else {
				lean = "r";
			}
		}
	}

	public double[] update(double sweepline)
	{
		if (!site2.boundary) {
			return Volornoi.site_intersect(site1, site2, sweepline, lean);
		} else {
			//the only other boundary site is the floor where y = 0
			//equ1 = [site1[0], (site1[1]+sweepline)/2, 2*(site1[1]-sweepline)]	#h, k, p format
			double discriminant = Math.Sqrt(-((site1[1]+sweepline)/2) * (2*(site1[1]-sweepline)));
			if (lean == "r") {
				return new double[] {-1, discriminant + site1[0]};
			} else if (lean == "l"){
				return new double[] {-discriminant + site1[0], -1};
			} else {
				return new double[] {-discriminant + site1[0], discriminant + site1[0]};
			}
		}
	}

	//sets the availiable point based on the given x and sweepline
	//if the function takes uo the kadt availabke point, it return a site to be removed from the beachline
	public bool setPoint(List<double> point, double sweepline = 0)
	{
		if (startPoint.SequenceEqual(new List<double> {0,0})) {
			startPoint = point;
			//incase of boundary point find the side of the collision and make the lean the other side
			if (site2.boundary) {
				double[] collisions = update(sweepline);
				//find the matching side
				//copied from intersect function
				for (int i=0; i < 2; i++) {
					if (Math.Abs(collisions[i]-point[0]) < .005) {	//.005 is the margin of error due to floating point calculations. I changed it due to an error during stress testing
						if (i == 0) {	//if the left value and point match
							lean = "r";
						} else {
							lean = "l";
						}
					}
				}
			} else if (site1[1] - site2[1] != 0) {	//calculate the lean between 2 NON-boundary points
				//////new
				//get the higher site
				if (site2[1] > site1[1]) {
					//calculate if on left or right side
					if (point[0] < site2[0]) {
						lean = "r";
					} else {
						lean = "l";
					}
				} else {
					//calculate if on left or right side
					if (point[0] < site1[0]) {
						lean = "r";
					} else {
						lean = "l";
					}
				}
			} else {
				lean = "l";
			}
		} else {
			//return the finished edge to be added to their respective Cells
			endPoint = point;
			return true;
		}
		//the edge isn't complete
		return false;
	}
}


public partial class Cell
{
	public List<double> site;
	public List<List<List<double>>> edges = new List<List<List<double>>>();
	public List<List<double>> neighbors = new List<List<double>>();
	public List<List<double>> polygon = new List<List<double>>();
	public string corner = "";

	public Cell(List<double> siteToSet)
	{
		site = siteToSet;
	}

	public void addEdge(HalfEdge edge)
	{
		edges.Add(new List<List<double>> {edge.startPoint, edge.endPoint});
		neighbors.Add(new List<double> (edge.site1.pos));
		neighbors.Add(new List<double> (edge.site2.pos));
	}

	public void orderEdges(List<double> size)
	{
		//this function is the final step and I decided it will also handle removing all copies from the neighbor list
		//List<List<double>> noCpyLst = neighbors.ConvertAll(s => s).ToList();
		neighbors.RemoveAll(item => item == site);
		neighbors.RemoveAll(item => item == new List<double> {-1,-1});

		if(corner == "l" || corner == "r") {
			List<List<double>> corner_edge = Cell.edgesFromCorner(corner, edges, size);
			if (corner_edge != new List<List<double>> {new List<double> {-1, -1}}) {
				edges.Add(corner_edge);
			}
		}

		List<List<List<double>>> lst = edges.ConvertAll(s => s).ToList();  //creates a copy of arguement array so the global array isn't edited by the deletions
		polygon.AddRange(lst[0]);
		lst.RemoveAt(0);
		foreach (var i in Enumerable.Range(0, lst.Count)) {
			int old_len = lst.Count;
			foreach (var j in Enumerable.Range(0, lst.Count)) {
				List<List<double>> edge = lst[j];
				
				if (edge[0] == polygon[0]) {
					polygon.Insert(0, edge[1]);
					lst.RemoveAt(j);
					break;
				}
				if (edge[1] == polygon[0]) {
					polygon.Insert(0, edge[0]);
					lst.RemoveAt(j);
					break;
				}
				if (edge[0] == polygon.Last()) {
					polygon.Add(edge[1]);
					lst.RemoveAt(j);
					break;
				}
				if (edge[1] == polygon.Last()) {
					polygon.Add(edge[0]);
					lst.RemoveAt(j);
					break;
				}
			}
			if (old_len == lst.Count) { //no points were removed/ gap in edge list
				//find the matching point that has the same x as the detached edge
				foreach (var j in Enumerable.Range(0, lst.Count)) {
					List<List<double>> edge = lst[j];
					//find the end point in the polygon that matches the detached edge's x
					if (polygon[0][0] == edge[0][0]) {
						polygon.Insert(0, edge[0]);
						polygon.Insert(0, edge[1]);
						lst.RemoveAt(j);
						break;
					} else if (polygon[0][0] == edge[1][0]) {
						polygon.Insert(0, edge[0]);
						polygon.Insert(0, edge[1]);
						lst.RemoveAt(j);
						break;
					}
					else if (polygon.Last()[0] == edge[0][0]) {
						polygon.AddRange(edge);
						lst.RemoveAt(j);
						break;
					}
					else if (polygon.Last()[0] == edge[1][0]) {
						edge.Reverse();
						polygon.AddRange(edge);
						lst.RemoveAt(j);
						break;
					}
				}
			}
		}
		
		//remove extra point that points to the polygon starting point
		if (polygon[0] == polygon.Last()) {
			polygon.RemoveAt(polygon.Count - 1);
		}
	}
	
	//Doesn't matter if edges are ordered or unordered
	static private List<List<double>> edgesFromCorner(string corner, List<List<List<double>>> edges, List<double> size)
	{
		//if the corner is top left or right
		List<List<double>> edge1;
		List<double> chosen_point = new List<double>();
		double highest_y = 0;
		foreach (List<List<double>> edge in edges)
		{
			if (edge[0][1] > highest_y) {
				highest_y = edge[0][1];
				chosen_point = edge[0];
			} if (edge[1][1] > highest_y) {
				highest_y = edge[1][1];
				chosen_point = edge[1];
			}
		}
		if (corner == "r") {
			edge1 = new List<List<double>> {size, chosen_point};
		} else {
			edge1 = new List<List<double>> {new List<double> {0, size[1]}, chosen_point};
		}
		if (edge1[0] != edge1[1]) {
			return edge1;
		} else {
			return new List<List<double>> {new List<double> {-1, -1}};
		}
	}

	//converts 2d to 1d list
	static private List<List<double>> UsingForLoop(List<List<List<double>>> array)
	{
		int len = 0;
		//get array length
		for (int i=0; i < array.Count ;i++) {
			len += array[i].Count;
		}

		List<List<double>> ret = new List<List<double>>(len);
		foreach (List<List<double>> i in array)
		{
			foreach (List<double> j in i)
			{
				ret.Add(j);
			}
		}
		return ret;
	}

	//return polygon in godot form for use
	public Godot.Collections.Array<Godot.Collections.Array<double>> getPolygon() {
		Godot.Collections.Array<Godot.Collections.Array<double>> Outarr = new Godot.Collections.Array<Godot.Collections.Array<double>> {};
		foreach(List<double> point in polygon) {
			Outarr.Add(new Godot.Collections.Array<double>(point));
		}
		return Outarr;
	}
}