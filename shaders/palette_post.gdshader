shader_type canvas_item;
render_mode unshaded;

// Screen texture for Godot 4.2+
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Palette configuration - DawnBringer 16 colors
uniform int palette_size : hint_range(1, 16) = 16;
uniform vec3 color_0 : source_color = vec3(0.094, 0.063, 0.063);
uniform vec3 color_1 : source_color = vec3(0.541, 0.278, 0.200);
uniform vec3 color_2 : source_color = vec3(0.898, 0.427, 0.235);
uniform vec3 color_3 : source_color = vec3(0.953, 0.741, 0.000);
uniform vec3 color_4 : source_color = vec3(0.988, 0.953, 0.600);
uniform vec3 color_5 : source_color = vec3(0.482, 0.635, 0.282);
uniform vec3 color_6 : source_color = vec3(0.118, 0.396, 0.294);
uniform vec3 color_7 : source_color = vec3(0.275, 0.608, 0.659);
uniform vec3 color_8 : source_color = vec3(0.173, 0.314, 0.447);
uniform vec3 color_9 : source_color = vec3(0.557, 0.455, 0.682);
uniform vec3 color_10 : source_color = vec3(0.345, 0.239, 0.384);
uniform vec3 color_11 : source_color = vec3(0.957, 0.957, 0.957);
uniform vec3 color_12 : source_color = vec3(0.702, 0.702, 0.702);
uniform vec3 color_13 : source_color = vec3(0.435, 0.435, 0.435);
uniform vec3 color_14 : source_color = vec3(0.235, 0.235, 0.235);
uniform vec3 color_15 : source_color = vec3(0.090, 0.090, 0.090);

// Dithering options
uniform bool use_dither = true;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.35;

// Additional tweaking
uniform float saturation : hint_range(0.0, 2.0) = 1.0;
uniform float contrast : hint_range(0.5, 2.0) = 1.0;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;

// 4x4 Bayer matrix for ordered dithering (0..1 range)
float bayer4(vec2 p) {
	ivec2 pos = ivec2(mod(p, 4.0));
	int x = pos.x;
	int y = pos.y;
	
	// Manual lookup for 4x4 Bayer matrix
	if (y == 0) {
		if (x == 0) return 0.0 / 15.0;
		if (x == 1) return 8.0 / 15.0;
		if (x == 2) return 2.0 / 15.0;
		if (x == 3) return 10.0 / 15.0;
	} else if (y == 1) {
		if (x == 0) return 12.0 / 15.0;
		if (x == 1) return 4.0 / 15.0;
		if (x == 2) return 14.0 / 15.0;
		if (x == 3) return 6.0 / 15.0;
	} else if (y == 2) {
		if (x == 0) return 3.0 / 15.0;
		if (x == 1) return 11.0 / 15.0;
		if (x == 2) return 1.0 / 15.0;
		if (x == 3) return 9.0 / 15.0;
	} else { // y == 3
		if (x == 0) return 15.0 / 15.0;
		if (x == 1) return 7.0 / 15.0;
		if (x == 2) return 13.0 / 15.0;
		if (x == 3) return 5.0 / 15.0;
	}
	return 0.0;
}

// Get palette color by index
vec3 get_palette_color(int index) {
	if (index == 0) return color_0;
	if (index == 1) return color_1;
	if (index == 2) return color_2;
	if (index == 3) return color_3;
	if (index == 4) return color_4;
	if (index == 5) return color_5;
	if (index == 6) return color_6;
	if (index == 7) return color_7;
	if (index == 8) return color_8;
	if (index == 9) return color_9;
	if (index == 10) return color_10;
	if (index == 11) return color_11;
	if (index == 12) return color_12;
	if (index == 13) return color_13;
	if (index == 14) return color_14;
	if (index == 15) return color_15;
	return color_0; // fallback
}

// Find closest color in the palette using perceptually-weighted distance
vec3 closest_palette_color(vec3 c) {
	int best_i = 0;
	float best_d = 1e9;
	
	for (int i = 0; i < palette_size; i++) {
		vec3 palette_color = get_palette_color(i);
		vec3 d = c - palette_color;
		// Luma-weighted distance for better perceptual matching
		float dist = dot(d * vec3(0.6, 1.0, 0.4), d * vec3(0.6, 1.0, 0.4));
		if (dist < best_d) {
			best_d = dist;
			best_i = i;
		}
	}
	return get_palette_color(best_i);
}

void fragment() {
	// Sample the screen texture using Godot 4.2+ syntax
	vec4 src = texture(screen_texture, SCREEN_UV);
	vec3 col = src.rgb;
	
	// Apply color adjustments before palette mapping
	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(gray), col, saturation);
	col = (col - 0.5) * contrast + 0.5;
	col *= brightness;
	col = clamp(col, 0.0, 1.0);
	
	// Apply dithering if enabled
	if (use_dither) {
		// Get pixel coordinates for dithering pattern
		vec2 pix = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
		float d = bayer4(pix) - 0.5;
		col += dither_strength * d / 255.0; // Scale down dither amount
		col = clamp(col, 0.0, 1.0);
	}
	
	// Map to closest palette color
	vec3 palette_color = closest_palette_color(col);
	
	COLOR = vec4(palette_color, src.a);
}