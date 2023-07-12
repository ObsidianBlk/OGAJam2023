shader_type canvas_item;
render_mode blend_mix;

/*
* Modified shader based of original shader sets by Deep-Fold
* Original Source: https://github.com/Deep-Fold/PixelPlanets
* License: MIT
*
* Modified by: ObsidianBlk
* Adapted to Godot 4 shader. Utility functions split into their own include file.
*/

#define USE_CLOUD_COLORS
#define UTIL_CIRCLENOISE
#define UTIL_SPHERIFY
#define UTIL_FBM

#include "res://shaders/planet/inc/planet_uniforms.gdshaderinc"
#include "res://shaders/planet/inc/planet_utils.gdshaderinc"

uniform float stretch : hint_range(1.0,3.0) = 2.0;
uniform float cloud_curve : hint_range(1.0, 2.0) = 1.3;
uniform float cloud_cover : hint_range(0.0, 1.0);

float cloud_alpha(vec2 uv) {
	float c_noise = 0.0;
	
	// more iterations for more turbulence
	for (int i = 0; i < 9; i++) {
		c_noise += circleNoise((uv * size * 0.3) + (float(i+1)+10.) + (vec2(time*time_speed, 0.0)));
	}
	float fbm = fbm(uv*size+c_noise + vec2(time*time_speed, 0.0));
	
	return fbm;
}

void fragment() {
	// pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	
	// distance to light source
	float d_light = distance(uv , light_origin);
	
	// cut out a circle
	float d_circle = distance(uv, vec2(0.5));
	float a = step(d_circle, 0.5);
	
	float d_to_center = distance(uv, vec2(0.5));
	
	uv = rotate(uv, rotation);
	
	// map to sphere
	uv = spherify(uv);
	// slightly make uv go down on the right, and up in the left
	uv.y += smoothstep(0.0, cloud_curve, abs(uv.x-0.4));
	
	
	float c = cloud_alpha(uv*vec2(1.0, stretch));
	
	// assign some colors based on cloud depth & distance from light
	vec4 col = base_color;
	if (c < cloud_cover + 0.03) {
		col = outline_color;
	}
	if (d_light + c*0.2 > light_border_1) {
		col = shadow_base_color;

	}
	if (d_light + c*0.2 > light_border_2) {
		col = shadow_outline_color;
	}
	
	c *= step(d_to_center, 0.5);
	COLOR = vec4(col.rgb, step(cloud_cover, c) * a * col.a);
}
