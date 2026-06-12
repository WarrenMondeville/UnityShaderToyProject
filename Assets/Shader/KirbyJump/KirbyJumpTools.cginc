// polynomial smooth min (from IQ)
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(b, a, h) - k * h * (1.0 - h);
}


float smax(float a, float b, float k)
{
    return -smin(-a, -b, k);
}

float2x2 rotmat(float a)
{
    return float2x2(cos(a), sin(a), -sin(a), cos(a));
}

float shoesDist(float3 p)
{
    float3 op = p;
    float d = 1e4;

    p.y -= 1.5;

    // right shoe
    op = p;
    p -= float3(-.5, -.6, -.9);
    p.yz = mul(rotmat(-.7),p.yz);
    p.xz = mul(rotmat(0.1),p.xz);
    d = min(d, -smin(p.y, -(length(p * float3(1.6, 1, 1)) - .64), .2));
    p = op;

    // left shoe
    op = p;
    p -= float3(.55, -.8, 0.4);
    p.x = -p.x;
    p.yz = mul(rotmat(1.4),p.yz);
    d = min(d, -smin(p.y, -(length(p * float3(1.6, 1, 1)) - .73), .2));
    p = op;
    return d;
}

float sceneDist(float3 p)
{
    float3 op = p;
    float d = shoesDist(p);

    d = min(d, p.y);
    p.y -= 1.5;

    // torso
    d = min(d, length(p) - 1.);


    // left arm
    op = p;
    p -= float3(.66, .7, 0);
    p.xz = mul(rotmat(-0.1) , p.xz);
    d = smin(d, (length(p * float3(1.8, 1, 1)) - .58), .07);
    p = op;

    // right arm
    op = p;
    p -= float3(-.75, 0.2, 0);
    d = smin(d, (length(p * float3(1, 1.5, 1)) - .54), .03);
    p = op;

    // mouth
    p.y -= .11;
    float md = smax(p.z + .84, smax(smax(p.x - .2, p.y - .075, .2), dot(p, float3(.7071, -.7071, 0)) - .1, .08), .04);
    p.x = -p.x;
    md = smax(md, smax(p.z + .84, smax(smax(p.x - .2, p.y - .075, .2), dot(p, float3(.7071, -.7071, 0)) - .1, .08), .01), .13);
    d = smax(d, -md, .012);

    // tongue
    p = op;
    d = smin(d, length((p - float3(0, .03, -.75)) * float3(1, 1, 1)) - .16, .01);

    return min(d, 10.);
}



float3 sceneNorm(float3 p)
{
    float3 e = float3(1e-3, 0, 0);
    float d = sceneDist(p);
    return normalize(float3(sceneDist(p + e.xyy) - sceneDist(p - e.xyy), sceneDist(p + e.yxy) - sceneDist(p - e.yxy),
        sceneDist(p + e.yyx) - sceneDist(p - e.yyx)));
}


// from simon green and others
float ambientOcclusion(float3 p, float3 n)
{
    const int steps = 4;
    const float delta = 0.15;

    float a = 0.0;
    float weight = 4.;
    for (int i = 1; i <= steps; i++) {
        float d = (float(i) / float(steps)) * delta;
        a += weight * (d - sceneDist(p + n * d));
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

// a re-shaped cosine, to make the peaks more pointy
float cos2(float x) { return cos(x - sin(x) / 3.); }

float starShape(float2 p)
{
    float a = atan2(p.y, p.x) + _Time.y / 3.;
    float l = pow(length(p), .8);
    float star = 1. - smoothstep(0., (3. - cos2(a * 5. * 2.)) * .02, l - .5 + cos2(a * 5.) * .1);
    return star;
}


void mainImage(out float4 fragColor, in float2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = fragCoord / _ScreenParams.xy;

    float an = cos(_Time.y) * .1;

    float2 ot = uv * 2. - 1.;
    ot.y *= _ScreenParams.y / _ScreenParams.x;
    float3 ro = float3(0., 1.4, 4.);
    float3 rd = normalize(float3(ot.xy, -1.3));

    rd.xz = mul(float2x2(cos(an), sin(an), sin(an), -cos(an)) , rd.xz);
    ro.xz = mul(float2x2(cos(an), sin(an), sin(an), -cos(an)) , ro.xz);

    float s = 20.;

    // primary ray
    float t = 0., d = 0.;
    for (int i = 0;i < 80;++i)
    {
        d = sceneDist(ro + rd * t);
        if (d < 1e-4)
            break;
        if (t > 10.)
            break;
        t += d * .9;
    }

    t = min(t, 10.0);

    // shadow ray
    float3 rp = ro + rd * t;
    float3 n = sceneNorm(rp);
    float st = 5e-3;
    float3 ld = normalize(float3(2, 4, -4));
    for (int i = 0;i < 20;++i)
    {
        d = sceneDist(rp + ld * st);
        if (d < 1e-5)
            break;
        if (st > 5.)
            break;
        st += d * 2.;
    }

    // ambient occlusion and shadowing
    float3 ao = ambientOcclusion(rp, n);
    float shad = lerp(.85, 1., step(5., st));

    ao *= lerp(.3, 1., .5 + .5 * n.y);

    // soft floor shadow
    if (rp.y < 1e-3)
        ao *= lerp(lerp(float3(1, .5, .7), float3(1,1,1), .4) * .6, float3(1,1,1), smoothstep(0., 1.6, length(rp.xz)));



    float3 diff = 1;
    float3 emit = 0;

    // skin
    diff *= float3(1.15, .3, .41) * 1.4;
    diff += .4 * lerp(1., 0., smoothstep(0., 1., length(rp.xy - float2(0., 1.9))));
    diff += .5 * lerp(1., 0., smoothstep(0., .5, length(rp.xy - float2(.7, 2.5))));
    diff += .36 * lerp(1., 0., smoothstep(0., .5, length(rp.xy - float2(-1.1, 1.8))));

    if (rp.y < 1e-3)
        diff = float3(.6, 1, .6);

    // mouth
    diff *= lerp(float3(1, .3, .2), float3(1,1,1), smoothstep(.97, .99, length(rp - float3(0, 1.5, 0))));

    // shoes
    diff = lerp(float3(1., .05, .1), diff, smoothstep(0., 0.01, shoesDist(rp)));
    diff += .2 * lerp(1., 0., smoothstep(0., .2, length(rp.xy - float2(-0.5, 1.4))));
    diff += .12 * lerp(1., 0., smoothstep(0., .25, length(rp.xy - float2(0.57, .3))));

    // bounce light from the floor
    diff += float3(.25, 1., .25) * smoothstep(-.3, 1.7, -rp.y + 1.) * max(0., -n.y) * .7;

    float3 orp = rp;
    rp.y -= 1.5;
    rp.x = abs(rp.x);

    // blushes
    diff *= lerp(float3(1, .5, .5), float3(1,1,1), smoothstep(.1, .15, length((rp.xy - float2(.4, .2)) * float2(1, 1.65))));

    rp.xy -= float2(.16, .45);
    rp.xy *= .9;
    orp = rp;
    rp.y = pow(abs(rp.y), 1.4) * sign(rp.y);

    // eye outline
    diff *= smoothstep(.058, .067, length((rp.xy) * float2(.9, .52)));

    rp = orp;
    rp.y += .08;
    rp.y -= pow(abs(rp.x), 2.) * 16.;

    // eye reflections
    emit += float3(.1, .5, 1.) * (1. - smoothstep(.03, .036, length((rp.xy) * float2(.7, .3)))) * max(0., -rp.y) * 10.;

    rp = orp;
    rp.y -= .12;

    // eye highlights
    emit += float3(1,1,1) * (1. - smoothstep(.03, .04, length((rp.xy) * float2(1., .48))));

    // fresnel
    diff += pow(clamp(1. - dot(-rd, n), 0., .9), 4.) * .5;

    // background and floor fade
    float3 backg = float3(1.15, .3, .41) * .9;
    ot.x += .6 + _Time.y / 50.;
    ot.y += cos(floor(ot.x * 2.) * 3.) * .1 + .2;
    ot.x = fmod(ot.x, .5) - .25;
    backg = lerp(backg, float3(1., 1., .5), .1 * starShape((ot - float2(0., .6)) * 8.) * smoothstep(9., 10., t));
    diff = lerp(diff, backg, smoothstep(.9, 10., t));

    fragColor.rgb = lerp(float3(.15, 0, 0), float3(1,1,1), ao) * shad * diff * 1.1;
    fragColor.rgb += emit;

    fragColor.rgb = pow(fragColor.rgb, 1. / 2.4);
    fragColor.a = 1;
}