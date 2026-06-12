#include "../ShaderToyTools.cginc"
#define rot(x) mat2(cos(x), sin(x), -sin(x), cos(x))

// set to true for a "fly through effect"
#define ROT_CAM true

// bend tunnel
#define BEND .8        

float spiral(vec2 uv, float i) {
    uv = mul(uv,rot(i * 3.14 - .4 * iTime));
    uv += .03 * sin(vec2(40, 70) * uv.yx);

    float d = length(uv);
    return smoothstep(1., -1., abs(d - .12) / fwidth(d) - .2);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;

    float col = 0.;

    for (float i = .02; i <= 1.; i += .02) {
        float z = fract(i - .1 * iTime);
        float fade = smoothstep(1., .8, z);
        vec2 UV = uv;
        if (ROT_CAM) {
            UV += sin(vec2(.3, .6) * iTime + z * BEND) * .3;
        }
        col += spiral(UV * z, i) * (.5 / z) * fade;
    }

    col = sqrt(col);

    fragColor = vec4(vec3(col, col, col), 1.);
}