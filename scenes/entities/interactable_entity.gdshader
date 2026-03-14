shader_type canvas_item;

uniform bool is_glitched = true;

uniform float shake_power : hint_range(0.0, 1.0) = 0.03;
uniform float color_split : hint_range(0.0, 1.0) = 0.0;
uniform float flicker_power : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	if (is_glitched) {
		float time_step = floor(TIME * 20.0);
		
		float x_shift = sin(time_step * 50.0) * shake_power;
		float y_shift = cos(time_step * 30.0) * shake_power;
		
		float split = color_split * 0.05;
		color.r = texture(TEXTURE, vec2(UV.x + x_shift + split, UV.y + y_shift)).r;
		color.g = texture(TEXTURE, vec2(UV.x + x_shift,       UV.y + y_shift)).g;
		color.b = texture(TEXTURE, vec2(UV.x + x_shift - split, UV.y + y_shift)).b;
		
		float noise = step(0.5, sin(TIME * 60.0));
		color.a = mix(color.a, color.a * noise, flicker_power);
		
	} else {
		COLOR = texture(TEXTURE, UV);
	}
	
	COLOR = color;
}