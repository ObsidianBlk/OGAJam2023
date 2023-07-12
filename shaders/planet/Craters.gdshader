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

#define USE_BASIC_COLORS
#define UTIL_CIRCLENOISE
#define UTIL_SPHERIFY

#include "res://shaders/planet/inc/planet_uniforms.gdshaderinc"
#include "res://shaders/planet/inc/planet_utils.gdshaderinc"

uniform float light_border : hint_range(0.0, 1.0) = 0.4;


float crater(vec2 uv) {
	float c = 1.0;
	for (int i = 0; i < 2; i++) {
		c *= circleNoise((uv * size) + (float(i+1)+10.) + vec2(time*time_speed,0.0));
	}
	return 1.0 - c;
}

void fragment() {
	//pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	
	// check distance from center & distance to light
	float d_circle = distance(uv, vec2(0.5));
	float d_light = distance(uv , vec2(light_origin));
	// cut out a circle
	// stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
	float a = step(d_circle, 0.49999);
	
	uv = rotate(uv, rotation);
	uv = spherify(uv);
		
	float c1 = crater(uv );
	float c2 = crater(uv +(light_origin-0.5)*0.03);
	vec4 col = color1;
	
	a *= step(0.5, c1);
	if (c2<c1-(0.5-d_light)*2.0) {
		col = color2;
	}
	if (d_light > light_border) {
		col = color2;
	} 

	// cut out a circle
	a*= step(d_circle, 0.5);
	COLOR = vec4(col.rgb, a * col.a);
}