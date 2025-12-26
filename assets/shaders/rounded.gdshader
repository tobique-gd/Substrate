shader_type canvas_item;

uniform float radius = 0.1;
uniform vec4 border_color : source_color = vec4(0.2588, 0.2588, 0.2588, 0.28);
uniform float border_width = 0.02;

void fragment() {
	vec2 uv = UV;
	float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	vec2 p = uv - 0.5;
	p.x *= aspect;

	vec2 b = vec2(0.5 * aspect, 0.5) - vec2(radius);
	vec2 q = abs(p) - b;

	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float aa = fwidth(d);

	float outer_mask = smoothstep(aa, -aa, d);
	float inner_mask = smoothstep(aa, -aa, d + border_width);

	float border_mask = outer_mask - inner_mask;

	vec4 col = texture(TEXTURE, uv * 0.6 + 0.2);
	vec3 final_rgb = mix(col.rgb, border_color.rgb, border_mask).rgb;

	COLOR = vec4(final_rgb, border_color.a * outer_mask);
}
