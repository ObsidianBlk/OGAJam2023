shader_type canvas_item;

uniform vec4 font_color : source_color = vec4(1.0);
uniform bool font_outline = false;
uniform vec4 font_outline_color : source_color = vec4(1);
uniform float font_outline_thickness : hint_range(0, 10) = 1.0;
uniform float strength = 0.001;
uniform float speed = 0.125;
uniform float frequency = 100;

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * font_outline_thickness;
	float offset = 0.0;
	float sineNoise = sin(frequency * UV.y - TIME * speed);
	offset = sineNoise * strength;
	vec2 uv = vec2(UV.x + offset, UV.y);
	
	float outline = texture(TEXTURE, uv + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, uv + vec2(0, size.y)).a;
	outline += texture(TEXTURE, uv + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, uv + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, uv + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, uv + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, uv + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, uv + vec2(size.x, -size.y)).a;
	outline = min(outline, 1.0);
	
	vec4 color = texture(TEXTURE, uv) * font_color;
	if (font_outline){
		COLOR = mix(color, font_outline_color, outline - color.a);
	} else {
		COLOR = color;
	}
}