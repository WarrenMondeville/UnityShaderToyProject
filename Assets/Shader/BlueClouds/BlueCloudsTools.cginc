#include "BlueCloudsCommon.cginc"
// Made by: TheNosiriN
// Use mouse to move the sun
// Look in "Common" tab for settings





vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03; float c = 2.43;
    float d = 0.59; float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}



void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = UV;
#ifdef MARGIN
    if (uv.y < marginSize || uv.y > 1.0 - marginSize) { fragColor = 0.0; return; }
#endif
    vec3 color;

    //from: https://www.shadertoy.com/view/3lXcW8
    float shaft = 0.0;
    vec3 shp = vec3(uv, max(0.0, (imageBrightness / 10.0) - 0.5)) - 0.5;
    for (float i = 0.0; i < 100.0; i++) {
        shp.xy = (shp.xy - SUNPOS) * 0.992 + SUNPOS;
        shp.xy += hash21(shp.xy) * 0.005;
        shaft += pow(
            saturate(texture(iChannel0, 0.5 + shp.xy).a), 10.0 / flareBrightness
        ) * exp(-i * (1.0 - radialLength));
    }
    //

    vec4 clouds = texture(iChannel0, uv);
    clouds.rgb = mix(clouds.rgb, pow(clouds.rgb, 2) * SUNCOLOR, min(2.0, shaft) * 0.2);

    color = ACESFilm(saturate(clouds.rgb));


    // Output to screen
    fragColor = vec4(color, 1.0);
}