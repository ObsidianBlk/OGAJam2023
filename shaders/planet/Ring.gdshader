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
#define UTIL_FBM

#include "res://shaders/planet/inc/planet_uniforms.gdshaderinc"
#include "res://shaders/planet/inc/planet_utils.gdshaderinc"

uniform float ring_width : hint_range(0.0, 0.15) = 0.1;
uniform float ring_perspective = 4.0;
uniform float scale_rel_to_planet = 6.0;

void fragment() {
	// pixelize uv
	vec2 uv = floor(UV*pixels)/pixels;
	
	float light_d = distance(uv, light_origin);
	uv = rotate(uv, rotation);
	
	// center is used to determine ring position
	vec2 uv_center = uv - vec2(0.0, 0.5);
	
	// tilt ring
	uv_center *= vec2(1.0, ring_perspective);
	float center_d = distance(uv_center,vec2(0.5, 0.0));
	
	
	// cut out 2 circles of different sizes and only intersection of the 2.
	float ring = smoothstep(0.5-ring_width*2.0, 0.5-ring_width, center_d);
	ring *= smoothstep(center_d-ring_width, center_d, 0.4);
	
	// pretend like the ring goes behind the planet by removing it if it's in the upper half.
	if (uv.y < 0.5) {
		ring *= step(1.0/scale_rel_to_planet, distance(uv,vec2(0.5)));
	}
	
	// rotate material in the ring
	uv_center = rotate(uv_center+vec2(0, 0.5), time*time_speed);
	// some noise
	ring *= fbm(uv_center*size);
	
	// apply some colors based on final value
	float posterized = floor((ring+pow(light_d, 2.0)*2.0)*4.0)/4.0;
	vec4 col;
	if (posterized <= 1.0) {
		col = texture(colorscheme, vec2(posterized, uv.y));
	} else {
		col = texture(dark_colorscheme, vec2(posterized-1.0, uv.y));
	}
	float ring_a = step(0.28, ring);
	COLOR = vec4(col.rgb, ring_a * col.a);
}