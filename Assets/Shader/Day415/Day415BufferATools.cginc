#include "Day415Common.cginc"
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    fragColor = 0;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 muv = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;

    vec2 uvuv = uv;
    float a = 0.;




    float s = 4.;
    vec2 offs = 0;


    float t = iTime * 0.1;


    float unenv = smoothstep(1., 0.9, mod(t / 2., 2.));
    if (iMouse.z < 1.) {

        //float id
        float side = mod(floor(t / 2.), 2.) * 2. - 1.;
        t = mod(t, 2.);
        side = sign(side);

        offs = vec2(
            0. + side * smoothstep(0., 0.25, t / 2.) * s + 0., 0. + sin(iTime) * 0.00001
        );
    }
    else {
        offs = vec2(
            0. + muv.x * s, 0. + muv.y * s * iResolution.x / iResolution.y
        );
    }


    float zoomAmt = 0.95;


    float zoomA = mix(0., 1., abs(offs.x) / s);
    float zoomB = smoothstep(0., 0.8, t - 1.) * (1. - zoomAmt) * 0.999;

    zoomB *= zoomA;
    zoomA *= zoomAmt;


    if (iMouse.z < 1.) {
        zoomA *= unenv;
        zoomB *= unenv;
        offs *= unenv;
    }


    //*zoomAmt
    float zoom = 6. * (1. -
        +zoomA
        - zoomB) + sin(iTime) * 0. - 0.;


    uv *= zoom;

    uv += offs;



    //uv = pmod(uv,0.76);




    vec2 ouv = uv;

    uv.x = abs(uv.x);

    float scale = 1. / pow(2., floor(log2(
        abs(
            max(
                (mod(abs(uv.x), 8.)) - 4.,
                (mod(abs(uv.y), 8.)) - 4.
            )
        )
    )));


    vec2 id = floor(uv * scale);
    vec2 fuv = fract(uv * scale);


    fuv = abs(fuv - 0.5) - 0.5;
    float d = abs(fuv.x);

    d = min(d, abs(fuv.y));

    d /= scale;

    float n = cyclicNoise(vec3(uvuv, floor(iTime * 10.)) * (51.), false, 0.);

    //d -= n*0.0001/dFdx(ouv.x);
    d -= n * dFdx(ouv.x) * 1.;



    if (iFrame > 2) {
        //vec2 uv = fragCoord/iResolution.xy;
        vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

        //uv -= scale*0.1;
        //uv -= 0.5;
        uv -= id / scale - offs;
        uv = mul(uv, rot(0.3 + iTime * 0.02 + id.x + sin(id.y)));

        uv += id / scale - offs;

        uv *= iResolution.y;
        uv += 0.5 * iResolution.xy;
        uv /= iResolution.xy;
        //uv += 0.5;
        fragColor.xyz = texture(iChannel0, uv).xyz * 0.5;
    }
    else {
        fragColor.xyz -= fragColor.xyz;
    }

    fragColor.xyz = mix(fragColor.xyz, 1., smoothstep(dFdx(ouv.x), 0., d - 0.0));

    n = cyclicNoise(vec3(uvuv, 4.) * 140., false, 0.);

    d = abs(abs(uvuv.x) - iResolution.x / iResolution.y * 0.5) - n * 0.005;

    d = min(d, abs(abs(uvuv.y) - 0.5) - n * 0.005);

    fragColor.xyz = mix(fragColor.xyz, 1., smoothstep(dFdx(uvuv.x), 0., d));







    //fragColor = vec4(col,1.0);
}