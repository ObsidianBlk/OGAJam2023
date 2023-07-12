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
#define UTIL_DITHER
#define UTIL_FBM

#include "res://shaders/planet/inc/planet_uniforms.gdshaderinc"
#include "res://shaders/planet/inc/planet_utils.gdshaderinc"

uniform vec4 color4 : source_color;
uniform vec4 river_col : source_color;
uniform vec4 river_col_dark : source_color;
uniform float river_cutoff : hint_range(0.0, 1.0);

void fragment() {
	// pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	
	bool dith = dither(uv, UV);
	// stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
	float a = step(length(uv-vec2(0.5)), 0.49999);
	
	// map to sphere
	uv = spherify(uv);
	float d_light = distance(uv , light_origin);
	
	// give planet a tilt
	uv = rotate(uv, rotation);
	
	// some scrolling noise for landmasses
	vec2 base_fbm_uv = (uv)*size+vec2(time*time_speed,0.0);
	
	// use multiple fbm's at different places so we can determine what color land gets
	float fbm1 = fbm(base_fbm_uv);
	float fbm2 = fbm(base_fbm_uv - light_origin*fbm1);
	float fbm3 = fbm(base_fbm_uv - light_origin*1.5*fbm1);
	float fbm4 = fbm(base_fbm_uv - light_origin*2.0*fbm1);
	
	float river_fbm = fbm(base_fbm_uv+fbm1*6.0);
	river_fbm = step(river_cutoff, river_fbm);
	
	// size of edge in which colors should be dithered
	float dither_border = (1.0/pixels)*dither_size;
	// lots of magic numbers here
	// you can mess with them, it changes the color distribution
	if (d_light < light_border_1) {
		fbm4 *= 0.9;
	}
	if (d_light > light_border_1) {
		fbm2 *= 1.05;
		fbm3 *= 1.05;
		fbm4 *= 1.05;
	} 
	if (d_light > light_border_2) {
		fbm2 *= 1.3;
		fbm3 *= 1.4;
		fbm4 *= 1.8;
		
		if (d_light < light_border_2 + dither_border) {
			if (dith || !should_dither) {
				fbm4 *= 0.5;
			}
		}
		
	} 
	
	// increase contrast on d_light
	d_light = pow(d_light, 2.0)*0.4;
	vec4 col = color4;
	if (fbm4 + d_light < fbm1*1.5) {
		col = color3;
	}
	if (fbm3 + d_light < fbm1*1.0) {
		col = color2;
	}
	if (fbm2 + d_light < fbm1) {
		col = color1;
	}
	if (river_fbm < fbm1*0.5) {
		col = river_col_dark;
		if (fbm4 + d_light < fbm1*1.5) {
			col = river_col;
		}
	}

	COLOR = vec4(col.rgb, a * col.a);
}