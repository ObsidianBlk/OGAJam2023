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
#define UTIL_SPHERIFY
#define UTIL_FBM

#include "res://shaders/planet/inc/planet_uniforms.gdshaderinc"
#include "res://shaders/planet/inc/planet_utils.gdshaderinc"

uniform float river_cutoff : hint_range(0.0, 1.0);

void fragment() {
	// pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	
	float d_light = distance(uv , light_origin);
	
	// cut out a circle
	float d_circle = distance(uv, vec2(0.5));
	// stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
	float a = step(d_circle, 0.49999);
	
	// give planet a tilt
	uv = rotate(uv, rotation);
	
	// map to sphere
	uv = spherify(uv);
	
	// some scrolling noise for landmasses
	float fbm1 = fbm(uv*size+vec2(time*time_speed,0.0));
	float river_fbm = fbm(uv + fbm1*2.5);
	
	// increase contrast on d_light
	d_light = pow(d_light, 2.0)*0.4;
	d_light -= d_light * river_fbm;
	
	river_fbm = step(river_cutoff, river_fbm);
	
	// apply colors
	vec4 col = color1;
	if (d_light > light_border_1) {
		col = color2;
	}
	if (d_light > light_border_2) {
		col = color3;
	}
	
	a *= step(river_cutoff, river_fbm);
	COLOR = vec4(col.rgb, a * col.a);
}