#include "../ShaderToyTools.cginc"
// freely inspired by nabr
// https://www.shadertoy.com/view/3dlXD7
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

#define tau 7.77777
vec2 mainSound(float time,float y)
{
    float x = y;
    float t = mod(time, 3.);
    float f = sin(tau * t * 180.) * exp(-10. * t);
    f -= f - (.25 + asin(f * t * float((mod(time, .3) > 0.1) ? 18. : .5)));
    f *= .0125 * abs(cos(f * t * 400.) - 2.);
    return f + cos(tau * step(time, sqrt(tau + x * 777.) * x + 1. - x + 30.1) * sin(vec2(1. - x * x * 0.3, 1. / x + x - .004) * .1 * .007) * .777) * 0.033;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{

    vec2 uv = (iResolution.xy - 2. * fragCoord.xy) / iResolution.x;
    float f = mainSound(-iTime, fragCoord.y).x;
    vec3 color = uv.y + 0.19 * cos(tau * asin(uv.x) + vec3(3, f * 0.7, f * 5.9) + iTime);

    vec2 uv2 = (iResolution.yx - 2. * fragCoord.x) / iResolution.y;
    float f2 = -(mainSound(iTime, fragCoord.y).x);
    vec3 color2 = uv2.y + 1500. * sin(-tau * sin(uv2.y) + vec3(30., f2 * -0.02, f2 - 3.14) + iTime);

    vec3 color3 = uv.x + 3. - sin(tau - sin(uv.x) * vec3(2, f * 39.0, f / 0.91) * (-iTime));

    fragColor.rgb = 3.1 - sqrt(color2 * color) * tau + color3;

    fragColor.a = 1.;
}




