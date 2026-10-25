shader_type spatial;
uniform vec4 shirt_color : source_color = vec4(0.14, 0.49, 0.52, 1.0);
void fragment() {
	ALBEDO = mix(COLOR.rgb, shirt_color.rgb, clamp(UV2.x, 0.0, 1.0));
	ROUGHNESS = 0.9;
}
