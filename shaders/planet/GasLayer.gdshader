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

#define USE_GASGIANT_COLORS
#define UTIL_TURBULENCE
#define UTIL_CIRCLENOISE
#define UTIL_SPHERIFY
#define UTIL_DITHER
#define UTIL_FBM

#include "res://shaders/planet/inc/planet_uniforms.gdshaderinc"
#include "res://shaders/planet/inc/planet_utils.gdshaderinc"

uniform float bands = 1.0;

void fragment() {
	// pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	float light_d = distance(uv, light_origin);
	
	// we use this value later to dither between colors
	bool dith = dither(uv, UV);
	
	// stepping over 0.5 instead of 0.49999 makes some pixels a little buggy
	float a = step(length(uv-vec2(0.5)), 0.49999);
	
	// rotate planet
	uv = rotate(uv, rotation);
	
	// map to sphere
	uv = spherify(uv);

	// a band is just one dimensional noise
	float band = fbm(vec2(0.0, uv.y*size*bands));
	
	// turbulence value is circles on top of each other
	float turb = turbulence(uv);

	// by layering multiple noise values & combining with turbulence and bands
	// we get some dynamic looking shape	
	float fbm1 = fbm(uv*size);
	float fbm2 = fbm(uv*vec2(1.0, 2.0)*size+fbm1+vec2(-time*time_speed,0.0)+turb);
	
	// all of this is just increasing some contrast & applying light
	fbm2 *= pow(band,2.0)*7.0;
	float light = fbm2 + light_d*1.8;
	fbm2 += pow(light_d, 1.0)-0.3;
	fbm2 = smoothstep(-0.2, 4.0-fbm2, light);
	
	// apply the dither value
	if (dith && should_dither) {
		fbm2 *= 1.1;
	}
	
	// finally add colors
	float posterized = floor(fbm2*4.0)/2.0;
	vec4 col;
	if (fbm2 < 0.625) {
		col = texture(colorscheme, vec2(posterized, uv.y));
	} else {
		col = texture(dark_colorscheme, vec2(posterized-1.0, uv.y));
	}
		
	COLOR = vec4(col.rgb, a * col.a);
}