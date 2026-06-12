#include "../ShaderToyTools.cginc"
#define T texture(iChannel0,.5+(p.xy*=.992)).rgb

#define radialLength 0.95     //0.5 - 1.0
#define imageBrightness 9.0   //0 - 10
#define flareBrightness 4.5   // 0 - 10

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec3 p = vec3(fragCoord / iResolution.xy, max(0.0, (imageBrightness / 10.0) - 0.5)) - 0.5;
    vec3 o = T;

    for (float i = 0.0; i < 100.0; i++)
    {
        p.z += pow(max(0.0, 0.5 - length(T)), 10.0 / flareBrightness) * exp(-i * (1.0 - (radialLength)));
    }

    vec3 flare = p.z * vec3(0.7, 0.9, 1.0); //tint

    fragColor = vec4(o * o + flare, 1.0);
}