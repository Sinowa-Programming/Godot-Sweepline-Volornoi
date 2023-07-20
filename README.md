# Godot-Sweepline-Volornoi

A Godot 4.X addon that generates and displays a volornoi diagram using a port of my python implementation of [Fortone's sweepline algorithm](https://en.wikipedia.org/wiki/Fortune%27s_algorithm). This project is a fun hobby project and I welcome you to fork it! :)

## Example Results
Image of shader display
![Image of shader display](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/images/shader_display_example.png)
Image of polygon display
![Image of Polygon Display](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/images/polygon_display_example.png)

## Features

* Can generate a svg file for quick loopup of cells
* Generates the polygons along with a nearest-neighbor graph
* Generated to a rectangular field
* Consistant cell coloring

## Operation through scripts
You can generate a volornoi diagram through code using this plugin.\
All examples taken from Example.gd
* To call the poisson (pseudo-random point generation) algorithm:
```GDScript
var points = Volornoi.poisson(radius, tries, size)	# Create the points
```
* To call the volornoi algorithm:
```GDScript
var out_dict = Volornoi.volornoi(points, size)	# Create the diagram
```


## Operation by using the Volornoi node

### Create a new diagram
* select a node
* select the **'New Volornoi Diagram'** button

### Edit the diagram
* toggle the **'Edit Mode'**. The button should turn green. You should be able to edit the diagram now.

### Add points
* Click inside of the red square to add points
* Use the **'Generate Field of Points'** button to get a set of points. 

### Remove points
* Right click on the point

### Process Points

#### step 1
You can:
* Don't toggle anything
* toggle **'Generate a color lookup diagram'** button
* toggle **'Create Polygon Cells (Experimental)'** button

#### step 2
* Press **'Compute Selected Diagram'** button

#### step 3
* If **'Generate a color lookup diagram'** is toggled an svg image will be saved. The svg image will be used for the lookup diagram and also for the simple shader that displays the cells.
* The diagram should have child polygon nodes to the Volornoi node if **'Create Polygon Cells (Experimental)'** is toggled.
* If you never selected either then nothing will be displayed, but the data will be stored in the colormap and graph variables of the volornoi_map node. You can then reload the diagram, without any processing, later.

### Additional Features
* You can save the diagram to a json file using the **'Save Selected Diagram'**
* You can load the diagram from a json file using the **'Load Selected Diagram'**
* You can clear the selected diagram using the **'Clear All Points'** button
* The **'Point Size'** value handles the size of the points when displayed.

### Final tutorial notes
* **You do not need to recompute if you change your mind in your display.** All of the data is stored in the color_map variable and can be used to reprocess the diagram by using the **'Reload Diagram'** button.

## Notes
* Due to the nature of geometry, there are many edge cases that occur while using this algorithm. Edges cases are rare and if they happen, slightly move the problem site 1 or 2 pixels. If possible, please also open a github issue with the problem point list, so I can resolve the edge case.
* While there may be errors in regards to invalid polygon data, the result should be fine.
* Errors with polygon generation occur if there are points too close together due to computer floating point inprecision.


## Data Structures
Sweepline Algorithm
```GDScript
func volornoi(_pointLst : Array, _size : Array) -> Dictionary
```
Poisson Algorithm
```GDScript
func poisson(_min_radius : float, tries : int, img_size : Array) -> Array
```
Simple Outline Shader
```GLSL
uniform float radius; # Only intergers
uniform vec4 border_color;
uniform sampler2D lookupDiagram;
```

## Known Bugs
* The volornoi node will misfunction if a root node.
* Godot may crash if you try to turn a large amount of volornoi cells into polygon nodes. ~2000 cells
* There is an edge case where there are more than 1 intersection underneath the borderline.**( Currently Working on )**
## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/LICENSE) file for details.

## Todo
* [x] Real time graph update
* [ ] Add code documentation

## Acknowledgments

* [Easily explains the fortone sweepline algorithm](https://blog.ivank.net/fortunes-algorithm-and-implementation.html)
* [Site that I ported the poisson algorithm from](https://sighack.com/post/poisson-disk-sampling-bridsons-algorithm)
