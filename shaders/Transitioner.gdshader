shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float progress : hint_range(0.0, 1.0);
uniform float smoothness : hint_range(0.0, 1.0);
uniform sampler2D mask;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	float value = (1.0 - texture(mask, UV).r) * (smoothness);
	float weight = smoothstep(progress, progress + smoothness, value + smoothness);
	COLOR = mix(COLOR, screen_color, weight);
}
