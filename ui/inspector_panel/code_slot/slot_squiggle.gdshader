shader_type canvas_item;

uniform bool is_active = false;
uniform float strength = 2.0;
uniform float frequency = 20.0;
uniform float speed = 15.0;

void vertex() {
	if (is_active) {
		VERTEX.y += sin(VERTEX.x * frequency + TIME * speed) * strength;
		VERTEX.x += cos(VERTEX.y * frequency + TIME * speed) * (strength * 0.5);
	}
}