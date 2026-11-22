shader_type spatial;

// Candy stripes (count on one axis) or a checkerboard (count on both axes)
// for Stumble Guys style obstacles.
uniform vec4 color_a : source_color = vec4(1.0, 0.25, 0.3, 1.0);
uniform vec4 color_b : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 count = vec2(1.0, 8.0);

void fragment() {
	vec2 cell = floor(UV * count);
	ALBEDO = mix(color_a.rgb, color_b.rgb, mod(cell.x + cell.y, 2.0));
	ROUGHNESS = 0.45;
}
