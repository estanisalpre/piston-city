shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 0.08) = 0.0;
uniform float speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	// TEMPORAL: prueba de visibilidad, ignora SCREEN_TEXTURE.
	COLOR = vec4(1.0, 0.0, 0.0, 1.0);
}
