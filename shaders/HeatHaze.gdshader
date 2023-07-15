shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform bool enabled = false;
uniform float strength = 0.001;
uniform float speed = 0.125;
uniform float frequency = 100;

void fragment(){
	float offset = 0.0;
	if (enabled){
		float sineNoise = sin(frequency * UV.y - TIME * speed);
		offset = sineNoise * strength;
	} 
	COLOR = texture(screen_texture, vec2(UV.x + offset, UV.y));
}