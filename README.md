# Godot-Sweepline-Volornoi

A Godot 4.X addon that generates and displays a voronoi diagram using a port of my python implementation of [Fortone's sweepline algorithm](https://en.wikipedia.org/wiki/Fortune%27s_algorithm). This project is a fun hobby project and I welcome you to fork it! :)

## Example Results
Image of shader display
![Image of shader display](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/images/shader_display_example.png)
Image of polygon display
![Image of Polygon Display](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/images/polygon_display_example.png)

## Features

* Can generate a svg file for quick loopup of cells
* Generates the polygons along with a nearest-neighbor graph
* Generates to a rectangular field
* Consistant cell coloring
* Save and loading of voronoi diagrams

## Documentation
This can be found on this repo's [wiki](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/wiki)

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
* The voronoi node will misfunction if a root node.
* Godot may crash if you try to turn a large amount of volornoi cells into polygon nodes. ~2000 cells
## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/LICENSE) file for details.

## Todo
* [x] Real time graph update
* [ ] Add code documentation
* [ ] Implement divide and conquer algorithm

## Acknowledgments

* [Easily explains the fortone sweepline algorithm](https://blog.ivank.net/fortunes-algorithm-and-implementation.html)
* [Site that I ported the poisson algorithm from](https://sighack.com/post/poisson-disk-sampling-bridsons-algorithm)
