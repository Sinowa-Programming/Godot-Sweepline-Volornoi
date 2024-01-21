shader_type canvas_item;
uniform float radius = 2;	//line width | ints recommended (given float to silence error)
uniform vec4 border_color = vec4(.1,.1,.1,1.0);
uniform sampler2D lookupDiagram;

void fragment() {
	vec2 pixel_size = 1.0 / vec2(textureSize(lookupDiagram, 0));

	//provides an simple outline for the diagram
	vec4 pixColor = texture(lookupDiagram, UV);
	
	for(float y = -radius; y <= radius; y++)
	{
		for(float x = -radius; x <= radius; x++)
		{
			if (abs(x + y) > 0.01)	//x and y at zero is the source pixel
			{
				vec4 neighbor = texture(lookupDiagram, UV + vec2(pixel_size.x * x, pixel_size.y * y));
				if(neighbor.rgba != pixColor)
				{
					COLOR = border_color;
					break;
				}
			}
		}
	} if (COLOR != border_color) {
		discard;
	}
	
}
