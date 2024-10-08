# Operation through scripts
You can generate a volornoi diagram through code using this plugin.
## VolornoiSweepline
### Properties
|                  |           |
|------------------|-----------|
| Dictionary       | cells     |
| Array[Vector2]   | pointlist |
| Array            | size      |
### Methods
|        |                     |
|--------|---------------------|
| void   | generate            |
| void   | relax               |
| String | generate_svg_string |
| void   | generate_astar      |

## Property Descriptions

### Dictionary cells
A dictionary that contains voronoi cells. Each entry is a cell that is stored as:
```(cell : Vector2) : [polygon : Array[Vector2], neigboring sites : Vector2]```. Ex(To access the neigboring sites): ```voronoi.cells[Vector2(10,10)][1]```
### Array[Vector2] pointlist
The list of points currently in the voronoi diagram. Is set every time generate is called
### Array size
The rectangular box that the voronoi diagram is generated in. Format: [left wall, right wall, floor, ceiling]. They **CANNOT** be negative and all points must be inside of the diagram. They ***CANNOT** be on the border or errors may occur.
```
     (0,0)--floor----+   
       |             |
   left wall     right wall
       |             |
       +---ceiling-(x,y)
```
## Method Descriptions

### void generate(point_list : Array[Vector2], sizebox : Array) -> void
Generates a volornoi diagram with ```point_list``` being the list of sites that the dual diagram is created around and ```sizebox``` being the rectange that the sites lay inside.

### void relax() -> void
Relaxes the cells present after ```voronoi.generate``` is using the Lloyd's relaxation
algorithm.

### String generate_svg_string(color_map : Dictionary) -> String
Generates an svg string, with ```color_map``` being an additional parameter that if not ```{}```, will populate each cell with their respective color. 

### void generate_astar(astar_node : AStar2D) -> AStar2D
Takes in an ```Astar2D``` node and populates it with the triangulation data from the voronoi diagram. Will fail if ```voronoi.generate``` is not called at least once to populate ```voronoi.cells```.