#include "../ShaderToyTools.cginc"
void mainImage(out vec4 f, in vec2 p) {

    vec3 q = iResolution, d = vec3(p.xy - .5 * q.xy, q.y) / q.y, c = vec3(0, .5, .7);

    q = d / (.1 - d.y);
    float a = _Time.y;
    float k = sin(0.2 * a);
    float w = q.x *= q.x -= .05 * k * k * k * q.z * q.z;
    f = 0;
    f.xyz = d.y > .04 ? c :
        sin(4. * q.z + 40. * a) > 0. ?
        w > 2. ? c.xyx : w > 1.2 ? d.zzz : c.yyy :
        w > 2. ? c.xzx : w > 1.2 ? c.yxx * 2. : (w > .004 ? c : d).zzz;

}