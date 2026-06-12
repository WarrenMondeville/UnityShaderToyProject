#include "BlueCloudsCommon.cginc"
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (6.0 * f * f - 15.0 * f + 10.0);

    return mix(
        mix(hash21(i + vec2(0.0, 0.0)), hash21(i + vec2(1.0, 0.0)), u.x),
        mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x),
        u.y);
}
float cloud(vec2 p)
{
    vec2 time = TIME * 0.2;

    float r = texture(iChannel1, p + time * 0.5).r;

    p += time;
    float f = 0.0, a = 1.0;
    for (int i = 0; i < 5; i++) {
        f += (noise(p) + texture(iChannel1, p).r * 0.5) * a;
        p = (mul(M2, p) + time) * 2.0;
        a *= 0.5;
    }

    f *= f;
    f = saturate(f);
    f = 1.0 - (1.0 - f) * (1.0 - f);
    return f;

}



void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
#ifdef BLUR
    if (fragCoord == vec2(0.5, 0.5)) { fragColor.a = iResolution.x; return; }
    vec4 pc = texelFetch(iChannel0, ivec2(0, 0), 0);
    if (iResolution.x != pc.a) { fragColor = vec4(0); return; }
#endif

    vec2 uv = UV;
#ifdef MARGIN
    if (uv.y < marginSize || uv.y > 1.0 - marginSize) { fragColor = 0.0; return; }
#endif
    uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;

    vec4 color;

    vec3 sky1 = vec3(0.2, 0.4, 0.6);
    vec3 sky2 = saturate(sky1 + vec3(0.2, 0.3, 0.4));


    float ambient = 0.15;
    float intensity = 1.25;

    float stepsinv = 1.0 / STEPS;

    vec2 sundir = SUNPOS;
    vec2 dist = mix(0.01, 0.03, saturate(length(sundir - uv)));

    vec2 dp = normalize(sundir - uv) * dist * stepsinv;
    float total = 0.0;
    vec2 p = uv;
    float fd = cloud(p);

    for (float i = 0.0; i < STEPS; ++i) {
        float h = i * stepsinv;
        p += dp * (1.0 + h * (hash21(p) * 0.75));
        float d = cloud(p);
        total += (saturate(fd - d) + ambient * stepsinv) * (1.0 - h);
    }
    total = saturate(total);

    vec3 sky = mix(sky2, sky1, uv.y);
    color.rgb = mix(sky * 0.8, SUNCOLOR, total) * intensity;
    color.rgb = 1.0 - (1.0 - color.rgb) * (1.0 - sky * 0.5);
    color.rgb = pow(color.rgb, 3.0);
    color.a = total;


    vec3 sun = saturate(0.03 / length(uv - sundir));
    sky += sun;

    color.rgb = mix(sky, color.rgb, fd);
    color.rgb = saturate(color.rgb);

#ifdef BLUR
    float st = 1.0 / (0.5 / iTimeDelta);
    color.rgb = texture(iChannel0, UV).rgb * (1.0 - st) + color.rgb * st;
#endif


    fragColor = color;
}