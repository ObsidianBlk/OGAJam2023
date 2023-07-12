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

void fragment() {
	//pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	
	bool dith = dither(uv, UV);
	
	// check distance distance to light
	float d_light = distance(uv , vec2(light_origin));
	
	// cut out a circle
	float d_circle = distance(uv, vec2(0.5));
	// stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
	float a = step(d_circle, 0.49999);
	
	uv = spherify(uv);
	uv = rotate(uv, rotation);
	
	// get a noise value with light distance added
	d_light += fbm(uv*size+vec2(time*time_speed, 0.0))*0.3; // change the magic 0.3 here for different light strengths
	
	// size of edge in which colors should be dithered
	float dither_border = (1.0/pixels)*dither_size;

	// now we can assign colors based on distance to light origin
	vec4 col = color1;
	if (d_light > light_border_1) {
		col = color2;
		if (d_light < light_border_1 + dither_border && (dith || !should_dither)) {
			col = color1;
		}
	}
	if (d_light > light_border_2) {
		col = color3;
		if (d_light < light_border_2 + dither_border && (dith || !should_dither)) {
			col = color2;
		}
	}
	
	COLOR = vec4(col.rgb, a * col.a);
}