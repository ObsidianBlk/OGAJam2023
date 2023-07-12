/*
* Modified shader based of original shader sets by Deep-Fold
* Original Source: https://github.com/Deep-Fold/PixelPlanets
* License: MIT
*
* Modified by: ObsidianBlk
* This files includes the uniform variable definitions used by most shaders
*/

uniform float rotation : hint_range(0.0, 6.28) = 1.0;
uniform vec2 light_origin = vec2(0.39, 0.39);
uniform float dither_size : hint_range(0.0, 10.0) = 2.0;
uniform float light_border_1 : hint_range(0.0, 1.0) = 0.4;
uniform float light_border_2 : hint_range(0.0, 1.0) = 0.6;

#ifdef USE_BASIC_COLORS
uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
#endif
#ifdef USE_CLOUD_COLORS
uniform vec4 base_color : source_color;
uniform vec4 outline_color : source_color;
uniform vec4 shadow_base_color : source_color;
uniform vec4 shadow_outline_color : source_color;
#endif
#ifdef USE_GASGIANT_COLORS
uniform sampler2D colorscheme;
uniform sampler2D dark_colorscheme;
#endif

uniform bool should_dither = true;