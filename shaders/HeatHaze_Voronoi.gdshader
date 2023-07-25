shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform bool use_screen_texture = true;
uniform bool enabled = false;
uniform float strength = 0.005;
uniform float speed = 0.125;
uniform float density = 50;
uniform float angle_offset = 30.0;
uniform float angle_speed = 10.0;


// voronoi_random_noise() and voronoi() adapted from...
// https://docs.unity3d.com/Packages/com.unity.shadergraph@6.9/manual/Voronoi-Node.html
vec2 voronoi_random_noise(vec2 uv, float offset){
	mat2 m = mat2(vec2(15.27, 47.63), vec2(99.41, 89.98));
	vec2 fuv = fract(sin(m * uv) * 46839.32);
	return vec2(sin(fuv.y * offset)*0.5 + 0.5, cos(fuv.x * offset)*0.5 + 0.5);
}

vec2 voronoi(vec2 uv, float angleOffset, float cellDensity){
	vec2 g = floor(uv * cellDensity);
	vec2 f = fract(uv * cellDensity);
	vec2 res = vec2(8.0, 0.0);
	
	for(int y=-1; y<=1; y++){
		for (int x=-1; x<=1; x++){
			vec2 lattice = vec2(float(x), float(y));
			vec2 offset = voronoi_random_noise(lattice + g, angleOffset);
			
			float d = distance(lattice + offset, f);
			if (d < res.x){
				res = vec2(d, offset.x);
			}
		}
	}
	
	return res;
}

// Shader fragment code adapted from...
// https://gamedevbill.com/heat-haze-shader-graph/
void fragment() {
	float offset = 0.0;
	if (enabled){
		vec2 noiseUV = UV - vec2(0, TIME * speed);
		float angle = angle_offset + sin(TIME) * angle_speed;
		vec2 noise = voronoi(noiseUV, angle, density);
		offset = noise.x * strength;
	}
	
	if (use_screen_texture){
		COLOR = texture(screen_texture, vec2(UV.x + offset, UV.y));
	} else {
		COLOR = texture(TEXTURE, vec2(UV.x + offset, UV.y));
	}
}

