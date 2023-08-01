## Operation through scripts
You can generate a volornoi diagram through code using this plugin.
All examples taken from generation_through_script.gd
### To call the poisson (pseudo-random point generation) algorithm:
```GDScript
Volornoi.poisson(radius, tries, size) -> Array	# Create the points
```
#### Input
* float radius - The min distance between two points. The max radius is twice as large.
* * Ex: ```10.5```
* int tries - The amount of different point placement attempts before moving on to the next point.
* * Ex: ```30```
* Array size - The size of the field that points will be generated for.
* * Ex: ```[100,100]```
#### Output
* Array - A list of points.
* * Ex: ````[[0,0],[1,1],[2,2],[3,3]]````

### To call the volornoi algorithm:
```GDScript
Volornoi.volornoi(points, size) -> Dictionary
```
#### Input
* Array points - The list of points for diagram generation.
* * Ex: ````[[0,0],[1,1],[2,2],[3,3]]````
* Array size - The size of the Voronoi diagram
* * Ex: ```[100,100]```
#### Output
* Dictionary - A dictionary contains the site and it's polygon shape and it's neighboring sites.
* * Ex: 
```GDScript
{
    [1,1] : [
        [   # The polygon shape
            [0,0],
            [0,2],
            [2,2],
            [2,0]

        ], 
        [   # The neighboring sites
            [4,4],
            [6,7]
        ]
    ],
    ...
}
```

### To save an svg file
```GDScript
Volornoi.save_as_svg(color_map : Dictionary, size : Array, save_location :  String) -> void
```
#### Input
* Dictionary color_map - Stores a list of color keys that each connect to a polygon
* * Ex: 
```GDScript
{
    Color(.2, .3, .5) : [
        [0,0],
        [0,2],
        [2,2],
        [2,0]
    ],
    Color(.3, .6, .9) : [
    ...
    ],
}
```
* Array size -  The size of the svg file
* * Ex: ```[100,100]```
* String save_location - The save location of the svg file
* * Ex: ```res://random/save/loc/map.svg```