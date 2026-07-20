shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 design_resolution = vec2(320.0, 180.0);

const int bayer[16] = {
	0, 8, 2, 10,
	12, 4, 14, 6,
	3, 11, 1, 9,
	15, 7, 13, 5
};

void fragment() {
	ivec2 pix = ivec2(floor(SCREEN_UV * design_resolution));
	float threshold = (float(bayer[(pix.y % 4) * 4 + (pix.x % 4)]) + 0.5) / 16.0;
	COLOR = vec4(fade_color.rgb, progress > threshold ? fade_color.a : 0.0);
}
