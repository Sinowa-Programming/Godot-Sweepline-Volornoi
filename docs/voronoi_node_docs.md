# Operation by using the Volornoi node

## Create a new diagram
* select a parent node
* select the **'New Volornoi Diagram'** button

## Edit the diagram
* toggle the **'Edit Mode'**. The button should turn green. You should be able to edit the diagram now.

## Add points
* Click inside of the red square to add points
* Use the **'Generate Field of Points'** button to get a set of points using poisson disk sampling 

## Remove points
* Right click on the point
* Clear the selected diagram using the **'Clear All Points'** button

## Process Points
### 'Generate a color lookup diagram' button
* Creates an svg file that reflects the Voronoi diagram
### 'Create Polygon Cells' button
* Creates a child node that has a polygon node for each cell in the Voronoi diagram

### 'Reload Diagram' button
* A manual way for you to reload the diagram. You need to do this if you toggle real time graph update off.
### 'Real Time Graph Update' toggle
* Will auto recompute the graph for every change you do. It is recommended you turn off this feature when your program starts lagging.


## Saving/Loading
* You can save the diagram to a json file using the **'Save Selected Diagram'**
* You can load the diagram from a json file using the **'Load Selected Diagram'**

## Graph Display
* The **'Show Graph'** toggle toggles the visibility of the diagram.
* The **'Point Size'** value handles the size of the points displayed.
* The **'Line Width'** value handles the width of the line of the nearest neighbor graph along with the border width.