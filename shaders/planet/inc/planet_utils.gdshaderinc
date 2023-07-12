
/*
* Modified shader based of original shader sets by Deep-Fold
* Original Source: https://github.com/Deep-Fold/PixelPlanets
* License: MIT
*
* Modified by: ObsidianBlk
* This files includes the uniform variable definitions and utility functions shared
* by all shaders.
*/

// Shared uniforms required by all shaders!
uniform float pixels : hint_range(10,100);
uniform float size = 50.0;
uniform int OCTAVES : hint_range(0, 20, 1);
uniform float seed: hint_range(1, 10);

uniform float time = 0.0;
uniform float time_speed : hint_range(0.0, 1.0) = 0.2;


float rand(vec2 coord) {
	coord = mod(coord, vec2(1.0,1.0)*round(size));
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 15.5453 * seed);
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}


vec2 rotate(vec2 coord, float angle){
	coord -= 0.5;
	coord *= mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	return coord + 0.5;
}

#ifdef UTIL_FBM
float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES ; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}
#endif

#ifdef UTIL_DITHER
bool dither(vec2 uv1, vec2 uv2) {
	return mod(uv1.x+uv2.y,2.0/pixels) <= 1.0 / pixels;
}
#endif

#ifdef UTIL_SPHERIFY
vec2 spherify(vec2 uv) {
	vec2 centered= uv *2.0-1.0;
	float z = sqrt(1.0 - dot(centered.xy, centered.xy));
	vec2 sphere = centered/(z + 1.0);
	return sphere * 0.5+0.5;
}
#endif

#ifdef UTIL_CIRCLENOISE
// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
float circleNoise(vec2 uv) {
    float uv_y = floor(uv.y);
    uv.x += uv_y*.31;
    vec2 f = fract(uv);
	float h = rand(vec2(floor(uv.x),floor(uv_y)));
    float m = (length(f-0.25-(h*0.5)));
    float r = h*0.25;
    return m = smoothstep(r-.10*r,r,m);
}
#endif

#ifdef UTIL_TURBULENCE
float turbulence(vec2 uv) {
	float c_noise = 0.0;
	
	
	// more iterations for more turbulence
	for (int i = 0; i < 10; i++) {
		c_noise += circleNoise((uv * size *0.3) + (float(i+1)+10.) + (vec2(time * time_speed, 0.0)));
	}
	return c_noise;
}
#endif
