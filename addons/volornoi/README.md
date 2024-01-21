# Godot-Sweepline-Volornoi

A Godot 4.X addon that generates and displays a volornoi diagram using  [Fortone's sweepline algorithm](https://en.wikipedia.org/wiki/Fortune%27s_algorithm). This project is a fun hobby project and I welcome you to fork it! :)

## Example Results
![Image of diagram displayed through a shader](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/images/shader_display_example.png)
![Image of a diagram displayed through Polygon2D](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/images/polygon_display_example.png)

## Features
* Generate cells along with a nearest-neighbor graph 
* [Lloyd's relaxation algorithm](https://en.wikipedia.org/wiki/Lloyd%27s_algorithm)
* Generated to a rectangular field

## Operation
You can generate a volornoi diagram through code using this plugin.
See [example.tscn](path/to/example.tscn) for a runnable example.

* To call the volornoi algorithm:
```GDScript
var point_list : Array[Vector2] = [Vector2(1,1), Vector2(3,1), Vector2(3,3), Vector2(2,2), Vector2(1,3)]
var voronoi : VoronoiSweepline = VoronoiSweepline.new()
voronoi.generate( point_list, [0, 4, 0, 4 ])
```
* VoronoiSweepline.generate parameters:
* * point_list -  The list of seed points that the algorithm uses. Must be in a Array[ Vector2 ] format.
* * sizebox - The area that the algorithm is iterating over. [left wall, right wall, floor, ceiling]. They **CANNOT** be negative and all points must be inside of the diagram. They cannot be on the border or errors may occur.
  ```
     (0,0)--floor----+   
       |             |
   left wall     right wall
       |             |
       +---ceiling-(x,y)
    ```
* To use Lyod's relaxation algorithm
```GDScript
voronoi.relax()
```

## Notes
* Errors with polygon generation occur if there are points too close together due to computer floating point inprecision. Try to keep points at least 1 away from each other to minimize errors. Even further to ensure no errors occur.
* To relax the diagram you have to generate the diagram first so there are cells to relax


## Data Structures
Sweepline Algorithm
```GDScript
class VoronoiSweepline:
    func _init() -> void
    func generate(point_list : Array[Vector2], sizebox : Array) -> void
    func relax() -> void
    func process_cell_chunk( chunk : Array, start_idx : int, output_lst : Array[Vector2]) -> void
    func calc_centroid(pointlist : Array) -> Vector2
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Sinowa-Programming/Godot-Sweepline-Volornoi/blob/main/LICENSE) file for details.


## Acknowledgments
* [Easily explains the fortone sweepline algorithm](https://blog.ivank.net/fortunes-algorithm-and-implementation.html)