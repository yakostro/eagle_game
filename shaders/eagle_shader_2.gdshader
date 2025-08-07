shader_type canvas_item;

// Параметры для настройки
uniform float saturation = 0.8; // меньше — тусклее
uniform float blend_strength = 0.6; // сила эффекта шума
uniform float noise_scale = 8.0; // масштаб шума
uniform float noise_intensity = 0.3; // интенсивность шума
uniform float noise_roughness = 0.5; // шероховатость шума

// Новые параметры для стилизации
uniform float outline_strength = 0.3; // сила обводки
uniform vec3 outline_color = vec3(0.1, 0.1, 0.1); // цвет обводки
uniform float contrast = 1.2; // контрастность
uniform float brightness = 0.9; // яркость
uniform float color_temperature = 0.0; // цветовая температура (-1 холодный, 1 теплый)
uniform float stylization_strength = 0.6; // сила стилизации

// Функция для создания шума
float noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Функция для создания более сложного шума (Perlin-like)
float smooth_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Функция для создания многослойного шума
float layered_noise(vec2 uv, float scale, float roughness) {
    float noise_value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    
    for(int i = 0; i < 4; i++) {
        noise_value += smooth_noise(uv * frequency * scale) * amplitude;
        amplitude *= roughness;
        frequency *= 2.0;
    }
    
    return noise_value;
}

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // Создаем живописный шум
    vec2 noise_uv = UV * noise_scale;
    float brush_noise = layered_noise(noise_uv, 1.0, noise_roughness);
    
    // Преобразуем шум в живописный эффект
    float brush_effect = smoothstep(0.9, 0.9, brush_noise);
    brush_effect = mix(0.8, 1.2, brush_effect); // варьируем яркость
    
    // Применяем шум как живописную текстуру
    base_color.rgb *= brush_effect;
    base_color.rgb = mix(base_color.rgb, base_color.rgb * brush_effect, blend_strength);
    
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