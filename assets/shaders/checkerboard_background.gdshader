shader_type sky;

uniform sampler2D checker_texture : source_color;

void sky() {
	COLOR = texture(checker_texture, SCREEN_UV).rgb;

}