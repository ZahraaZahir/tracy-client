shader_type canvas_item;

uniform bool is_glitched = true;
uniform float jitter_power : hint_range(0.0, 1.0) = 0.02;
uniform float color_split : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 pixel_color = texture(TEXTURE, UV);
	
	if (is_glitched) {
		float shift = sin(TIME * 40.0) * jitter_power;
		
		float r = texture(TEXTURE, vec2(UV.x + shift, UV.y)).r;
		float g = pixel_color.g;
		float b = texture(TEXTURE, vec2(UV.x - shift, UV.y)).b;
		
		float flicker = step(0.95, sin(TIME * 100.0));
		COLOR = vec4(r, g, b, pixel_color.a - flicker);
	} else {
		COLOR = pixel_color;
	}
}