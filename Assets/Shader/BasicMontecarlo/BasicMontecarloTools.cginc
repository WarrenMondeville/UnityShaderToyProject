#include "../ShaderToyTools.cginc"
// Created by inigo quilez - iq/2016
// I share this piece (art and code) here in Shadertoy and through its Public API, only for educational purposes. 
// You cannot use, sell, share or host this piece or modifications of it as part of your own commercial or non-commercial product, website or project.
// You can share a link to it or an unmodified screenshot of it provided you attribute "by Inigo Quilez, @iquilezles and iquilezles.org". 
// If you are a teacher, lecturer, educator or similar and these conditions are too restrictive for your needs, please contact me and we'll work it out.

// Display : average down and do gamma adjustment

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    vec4 data = texture(iChannel0, uv);
    vec3 col = data.xyz / data.w;

    // gamma
    col = pow(col, vec3(0.4545,0.4545,0.4545));

    // color grading and vigneting
    col = pow(col, vec3(0.8, 0.85, 0.9));

    col *= 0.5 + 0.5 * pow(16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y), 0.1);

    fragColor = vec4(col, 1.0);
}