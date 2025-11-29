shader_type canvas_item;

uniform float radius = 0.1;
uniform float exposure = 0.0;
uniform bool focused = false;

void fragment() {
	vec2 uv = UV;
	float aspect = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	vec2 p = uv - 0.5;
	p.x *= aspect;

	vec2 b = vec2(0.5 * aspect, 0.5) - vec2(radius);
	vec2 q = abs(p) - b;

	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	float aa = fwidth(d);
	float mask = smoothstep(aa, -aa, d);

	vec4 col = texture(TEXTURE, uv);
	col.rgb *= exp2(exposure);
	col.rgb = col.rgb / (1.0 + col.rgb); // Reinhard tone mapping
	col *= mask;

	COLOR = vec4(col.rgb, col.a);

	if (focused) {
		COLOR *= vec4(0.8, 0.8, 0.8, 1.0);
	}

}
