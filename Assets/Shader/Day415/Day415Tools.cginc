//https://www.shadertoy.com/view/3lcfWn
#include "Day415Common.cginc"
// http://roy.red/infinite-regression-.html#infinite-regression

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    fragColor = 0;
    fragCoord -= 0.5 * iResolution.xy;
    fragCoord *= 0.99;
    fragCoord += 0.5 * iResolution.xy;

    float n1d = texture(iChannel1, mod(fragCoord + vec2(float(iFrame), 0.), iResolution.xy / 4.)).x;
    vec3 n = texture(iChannel1, mod(fragCoord + n1d * 200., iResolution.xy / 4.)).xyz;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    fragColor.xyz = texture(iChannel0, fragCoord / iResolution.xy).xyz;

    fragColor.xyz = pow(fragColor.xyz, vec3(0.7, 1.1, 1.5));

    //fragColor.xyz = 1. - fragColor.xyz;

    fragColor.xyz = pow(fragColor.xyz, vec3(0.5545 - n * 0.15));


    //fragColor.xyz *= 1. - dot(uv,uv)*0.4;


    fragColor.xyz += n * 0.15;

}