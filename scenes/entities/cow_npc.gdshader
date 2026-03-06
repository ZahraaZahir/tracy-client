shader_type canvas_item;

uniform bool is_glitched = false;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    if (is_glitched) {
        float time_step = floor(TIME * 20.0);
        float x_shift = sin(time_step * 50.0) * 0.03; 

        float r = texture(TEXTURE, vec2(UV.x + x_shift, UV.y)).r;
        float b = texture(TEXTURE, vec2(UV.x - x_shift, UV.y)).b;
        
        float alpha_noise = step(0.1, sin(TIME * 100.0));
       
        COLOR = vec4(r, color.g, b, color.a * alpha_noise);
		
    } else {
        COLOR = color;
    }
}