#include "../ShaderToyTools.cginc"
float heart(vec2 i) {
    // From: https://www.shadertoy.com/view/ldVGzt by coyote & Fabrice
    i.y += .034;
    i *= 1.1;
    return sqrt(dot(i, i) - abs(i.x) * i.y);
}

float diamond(vec2 i) {
    i = abs(i);
    return (i.x + i.y);
}

float square(vec2 i) {
    i = abs(i);
    return max(i.x, i.y);
}

float circle(vec2 i) {
    return sqrt(i.x * i.x + i.y * i.y);
}

float honeycomb(vec2 i) {
    i.x *= .866;
    i = abs(i);
    return max(i.x + i.y * .5, i.y);
}

float segment(vec2 uv)
{
    uv = abs(uv);
    float f = max(0.45 + uv.x, 0.225 + uv.y + uv.x);
    return f;
}

float m(float a, float b)
{
    return min(a, b);
    //return 1./(1./a+1./b);
    //return length(vec2(a,b));
}

float sevenSegment(vec2 uv, int num)
{
    float seg = 5.0;
    seg = (num != -1 && num != 1 && num != 4 ? m(segment(uv.yx + vec2(-0.450, 0.000)), seg) : seg);
    seg = (num != -1 && num != 1 && num != 2 && num != 3 && num != 7 ? m(segment(uv.xy + vec2(0.225, -0.225)), seg) : seg);
    seg = (num != -1 && num != 5 && num != 6 ? m(segment(uv.xy + vec2(-0.225, -0.225)), seg) : seg);
    seg = (num != -1 && num != 0 && num != 1 && num != 7 ? m(segment(uv.yx + vec2(0.000, 0.000)), seg) : seg);
    seg = (num == 0 || num == 2 || num == 6 || num == 8 ? m(segment(uv.xy + vec2(0.225, 0.225)), seg) : seg);
    seg = (num != -1 && num != 2 ? m(segment(uv.xy + vec2(-0.225, 0.225)), seg) : seg);
    seg = (num != -1 && num != 1 && num != 4 && num != 7 ? m(segment(uv.yx + vec2(0.450, 0.000)), seg) : seg);

    return seg;
}

vec2 rotate(vec2 i, float a) {
    return mul(mat2(cos(a), -sin(a), sin(a), cos(a)), i);
}

float getShape(int nr, vec2 uv) {

    //return circle2(uv);

    bool outline = false;
    if (nr < 10)
        return sevenSegment(uv, nr) - .3;
    else {
        outline = (nr >= 15);
        nr = int(mod(float(nr), 5.));
    }

    float x = 0.0;
    if (nr == 0)
    {
        x = heart(uv);
    }
    else
    {
        if (nr == 1)
        {
            x = diamond(uv);
        }
        else
        {
            if (nr == 2)
            {
                x = square(uv);
            }
            else
            {
                if (nr == 3)
                {
                    x = circle(uv);
                }
                else
                {
                    x = honeycomb(uv);
                } 
            } 
        }
    }
    return outline ? 0.15 + abs(x - .1) : x;
}



void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv1 = (fragCoord.xy - iResolution.xy * .5) / iResolution.y;
    vec2 uv = uv1 * 5.0;

    float c = 1.0;
    if (iMouse.w > 0.5)
    {
        c = texture(iChannel1, uv - iMouse.xy * 5.0 / iResolution.xy).r * 1.2 - .1;
    }
        
    float gt = iTime * .5;
    for (float i = 0.0; i < 20.0; i++) {
        gt += i * 1.72;
        c *= clamp(getShape(int(i), 1.6 * (uv + vec2(sin(gt * 0.9) * 2. + cos(gt * (i / 37.))
                , sin(gt * 0.7) + cos(gt * (i / 23.))))) - .18, 0.0, 1.7);
    }
    float tC = smoothstep(0.0, 10.0, sqrt(c));
    fragColor = vec4(clamp(
        mix(vec3(1.7,1.7,1.7), vec3(.7, .7, 1.) * (0.5 + texture(iChannel0, vec2(uv1.y * 4., uv.x) + uv1 * vec2(7.0, .13)).rgr),tC
        * .15 * max(-.2, 6. - length(uv1)))
        * .18 * (5. - length(uv))
        , 0.0, 1.0)
        , 1.0);
}