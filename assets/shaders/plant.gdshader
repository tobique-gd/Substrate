shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_opacity_map : source_color;
uniform sampler2D opacity_map : source_color;
uniform sampler2D normal : source_color;
uniform sampler2D roughness : source_color;

varying mat3 mvnm;

void vertex() {
    mvnm = MODELVIEW_NORMAL_MATRIX;
}

void fragment() {
    vec4 ao = texture(albedo_opacity_map, UV);
    vec3 n = texture(normal, UV).rgb;

    NORMAL = normalize(mvnm * vec3(0.0, 1.0, 0.0));
	NORMAL_MAP = n;
    ALBEDO = ao.rgb;
    ROUGHNESS = clamp(texture(roughness, UV).r * 1.4, 0.0, 1.0);
	SPECULAR = 0.35;
    ALPHA = texture(opacity_map, UV).a;
    ALPHA_SCISSOR_THRESHOLD = 0.55;
    ALPHA_ANTIALIASING_EDGE = 0.1;
}
