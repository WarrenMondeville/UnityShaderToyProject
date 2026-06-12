#include "../ShaderToyTools.cginc"
mat2 rot(float a) {
    float c = cos(a); float s = sin(a);
    return mat2(c, s, -s, c);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy - 0.5 * iResolution.xy;
    uv *= 2.0 / iResolution.y;
    uv = mul(uv, 2.0 * rot(iTime));

    vec2 UV = fragCoord.xy - 0.5 * iResolution.xy;
    UV = mul(UV, rot(0.1 * sin(iTime)) * (1.0 + 0.05 * sin(0.5 * iTime)));
    UV += 0.5 * iResolution.xy;
    UV /= iResolution.xy;

    float s = abs(uv.x) + abs(uv.y); // "Square"

    fragColor = 0.95 * texture(iChannel0, UV);
    fragColor += 1.0 * (step(1.0, s) - step(1.025, s));
}