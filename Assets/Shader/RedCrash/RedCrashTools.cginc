#include "../ShaderToyTools.cginc"
/*
Procural image made for Revision 2021 4k Excutable Graphics competition

Released executable can be found here: https://demozoo.org/graphics/292427/
*/

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 res = iResolution.xy;
    vec2 frag = fragCoord.xy;
    vec2 uv = frag / res.xy;

    vec4 value = texture(iChannel0, uv);


    vec3 col = value.xyz / value.w;

    // basic "tonemapping"
    col = smoothstep(0., 1., col);
    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1);
}
