shader_type canvas_item;

uniform sampler2D brush_texture;
uniform float saturation = 0.8; // меньше — тусклее
uniform float blend_strength = 1.0; // сила текстуры
uniform float texture_scale = 4.0; // масштаб текстуры для настройки
uniform vec2 texture_offset = vec2(0.0, 0.0); // смещение текстуры

// Новые параметры для стилизации
uniform float outline_strength = 0.3; // сила обводки
uniform vec3 outline_color = vec3(0.1, 0.1, 0.1); // цвет обводки
uniform float contrast = 1.2; // контрастность
uniform float brightness = 0.9; // яркость
uniform float color_temperature = 0.0; // цветовая температура (-1 холодный, 1 теплый)
uniform float stylization_strength = 0.6; // сила стилизации

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // Применяем живописную текстуру
    vec2 tiled_uv = fract(UV * texture_scale + texture_offset);
    vec4 brush = texture(brush_texture, tiled_uv);
    
    // Смешиваем с текстурой кисти для живописного эффекта
    base_color.rgb = mix(base_color.rgb, base_color.rgb * brush.rgb, blend_strength);
    
    // Десатурация для более приглушенного вида
    float gray = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
    base_color.rgb = mix(vec3(gray), base_color.rgb, saturation);
    
    // Применяем контрастность
    base_color.rgb = (base_color.rgb - 0.5) * contrast + 0.5;
    
    // Применяем яркость
    base_color.rgb *= brightness;
    
    // Цветовая температура (теплые/холодные тона)
    vec3 warm_tint = vec3(1.1, 0.9, 0.8); // теплые тона
    vec3 cool_tint = vec3(0.8, 0.9, 1.1); // холодные тона
    vec3 temperature_tint = mix(cool_tint, warm_tint, (color_temperature + 1.0) * 0.5);
    base_color.rgb *= temperature_tint;
    
    // Стилизация - упрощение цветов для более мультяшного вида
    if (stylization_strength > 0.0) {
        // Квантование цветов (упрощение палитры)
        float quantization_levels = 4.0;
        base_color.rgb = floor(base_color.rgb * quantization_levels) / quantization_levels;
        
        // Усиление теней для более четких форм
        float shadow_threshold = 0.3;
        float shadow_strength = 0.7;
        vec3 shadow_color = base_color.rgb * shadow_strength;
        base_color.rgb = mix(shadow_color, base_color.rgb, step(shadow_threshold, gray));
    }
    
    // Добавляем обводку для более четких форм
    if (outline_strength > 0.0) {
        // Простая обводка на основе яркости
        float edge = 1.0 - smoothstep(0.4, 0.6, gray);
        base_color.rgb = mix(base_color.rgb, outline_color, edge * outline_strength);
    }
    
    COLOR = base_color;
}