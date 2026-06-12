#include "../ShaderToyTools.cginc"
/**
    3D Truchet / trying to build from my past 2d work.
    https://www.shadertoy.com/view/wtGyDy @pjkarlik

    However I do realize I'm catching the deformations from the UVs.
    Wanted to attempt before taking apart any of @Shane's or @Dr2's
    shaders.

    you can have fun by adding webcam/video to iChannel0
    and uncomment line 283/284


*/

#define R           iResolution
#define T           iTime
#define M           iMouse
#define S           smoothstep

#define PI          3.141592
#define PI2         PI*2.
#define MAX_DIST    135.
#define MIN_DIST    .001

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))

//The hash functions
float hash(float n) { return fract(sin(n) * 43.54); }
float hash21(vec2 p) { return fract(sin(dot(p, vec2(27.609, 57.583))) * 43.5453); }
// vec2 to vec2 hash.
// @Shane https://www.shadertoy.com/view/3d2fzK
vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(27, 57)));
    p = fract(vec2(262144, 32768) * n) * 2. - 1.;
    return sin(p * 6.2831853 + iTime * .4);
}
// Based on IQ's gradient noise formula.
float n2D3G(in vec2 p) {
    vec2 i = floor(p); p -= i;

    vec4 v;
    v.x = dot(hash22(i), p);
    v.y = dot(hash22(i + vec2(1, 0)), p - vec2(1, 0));
    v.z = dot(hash22(i + vec2(0, 1)), p - vec2(0, 1));
    v.w = dot(hash22(i + 1.), p - 1.);
    // Cubic interpolation.
    p = p * p * (3. - 2. * p);

    return mix(mix(v.x, v.y, p.x), mix(v.z, v.w, p.x), p.y);
}
//Sum noise
float noise(in vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3. - 2. * f);
    float n = p.x + p.y * 57.;
    float res = mix(mix(hash(n + 0.1), hash(n + 1.1), f.x),
        mix(hash(n + 57.1), hash(n + 58.1), f.x), f.y);
    return res;
}

vec3 getMouse(vec3 ro) {
    float x = M.xy == vec2(0,0) ? .0 : -(M.y / R.y * .25 - .125) * PI;
    float y = M.xy == vec2(0,0) ? .0 : (M.x / R.x * .5 - .25) * PI;
    ro.zy = mul(ro.zy,r2(x));
    ro.zx = mul(ro.zx,r2(y));
    return ro;
}

//http://mercury.sexy/hg_sdf/
float vmax(vec3 v) {
    return max(max(v.x, v.y), v.z);
}
float fBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, 0)) + vmax(min(d, 0)) - r;
}

// lazy globals
vec3 g_hp, s_hp;
vec2 g_id, s_id, g_uv, s_uv;
float g_hsh, s_hsh, travelSpeed, trackSpeed, tf;
float ga1, ga2, ga3, ga4, ga5, ga6;

// make id's uv's and other stuff for the shapes
vec4 getTruch(vec2 uv, float offset) {
    vec2 grid_uv = fract(uv) - .5;
    vec2 grid_id = floor(uv);
    // get every other tile odd / even
    float checker = mod(grid_id.y + grid_id.x, 2.) * 2. - 1.;

    // get hash for tile from id
    float n = hash21(grid_id);
    if (n < .5) grid_uv.x *= -1.;

    // arcs and angles for path and movements
    vec2 arc = grid_uv - sign(grid_uv.x + grid_uv.y + .0001) * .5;
    float angle = atan(arc.x, arc.y);
    float d = length(arc);

    float width = .25;
    float mask = 1. - S(.0, -.1, abs(length(arc) - .5) - width);

    // truchet uv coords
    vec2 tuv = vec2(
        fract(3. * checker * angle / 1.5707 + trackSpeed) + .5,
        (d - (.5 - width)) / (2. * width) * 2.
    );
    tuv.xy -= .5;

    // id for objects on truchet
    vec2 tid = vec2(floor(3. * checker * angle / 1.5707 + trackSpeed), 0.);
    //force to be 1 to 6
    tid = mod(tid, 6.);

    // exclusive or operation
    if (n < .5 ^ ^checker>0.) tuv.y = 1. - tuv.y;
    if (mod(tid.x, 2.) == 0.)  tuv.x = 1. - tuv.x;

    g_uv = tuv;
    g_id = tid;
    return vec4(mask, n, arc);
}

vec2 map(in vec3 p) {
    vec2 res = vec2(100., 2.);
    p.xy += vec2(travelSpeed, .5);

    vec4 mask = getTruch(p.xz * .25, p.y);

    // make candy treats
    vec3 tuv = vec3(g_uv.x, (p.y - 2.5) * 1.5, g_uv.y - .5);
    float sushi = fBox(tuv - vec3(.5, -.45, 0), vec3(.35, .25, .275), .001);

    if (sushi < res.x) {
        res = vec2(sushi, 4.);
        g_hp = tuv;
        g_uv = tuv.xz;
        g_hsh = mask.y;
    }

    // rails
    vec2 rtv = vec2(tuv.y, abs(tuv.z)) - vec2(-.35, .5);
    float rails = length(rtv) - .05;
    rails = min(length(rtv - vec2(-.275, .075)) - .025, rails);
    if (rails < res.x) {
        res = vec2(rails, 1.);
        g_hp = tuv;
    }

    // trruchet planks
    float truch = (length(p.y - 2.) - .05) + mask.x / PI2;
    if (truch < res.x) {
        res = vec2(truch, 3.);
        g_hp = p;
    }

    // water ground plane
    g_hsh = n2D3G((p.xz) + iTime) * .35;
    float base = (p.y - 1.5) + g_hsh;
    if (base < res.x) {
        res = vec2(base, 5.);
        g_hp = p;
    }

    return res;
}


vec2 marcher(in vec3 ro, in vec3 rd, int maxstep) {
    float t = 0., m = 0.;
    for (int i = 0; i < maxstep; i++) {
        vec2 d = map(ro + rd * t);
        m = d.y;
        if (abs(d.x) < MIN_DIST * t || t > MAX_DIST) break;
        t += i < 48 ? d.x * .25 : d.x * .85;
    }
    return vec2(t, m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 getNormal(vec3 p, float t) {
    float h = t * MIN_DIST;
    //prevent from inlining @spalmer 
#define ZERO (min(iFrame,0))
    vec3 n = vec3(0.0);
    for (int i = ZERO; i < 4; i++) {
        vec3 e = 0.5773 * (2. * vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.);
        n += e * map(p + e * h).x;
    }
    return normalize(n);
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos - p);
    float dif = clamp(dot(n, l), .01, 1.);
    float shadow = marcher(p + n * .008, l, 86).x;
    if (shadow < length(p - lpos)) dif *= .2;
    return dif;
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n) {
    float sca = 2., occ = 0.;
    for (int i = 0; i < 5; i++) {
        float hr = float(i + 1) * .17 / 5.;
        // map(pos/dont record hit point)
        float d = map(p + n * hr).x;
        occ += (hr - d) * sca;
        sca *= .9;
        if (sca > 1e5) break;
    }
    return clamp(1. - occ, 0., 1.);
}

vec3 getSpec(vec3 p, vec3 n, vec3 l, vec3 ro) {
    vec3 spec = vec3(0.);
    float strength = 0.75;
    vec3 view = normalize(p - ro);
    vec3 ref = reflect(l, n);
    float specValue = pow(max(dot(view, ref), 0.), 32.);
    return spec + strength * specValue;
}

vec3 hue(float t) {
    vec3 c = vec3(0.973, 1.000, 0.898),
        d = vec3(0.933, 0.714, 0.467),
        a = vec3(.45),
        b = vec3(.45);
    return a + b * cos(PI2 * t * c * d);
}

//@iq SDF functions
float circle(vec2 pt, vec2 center, float r) {
    float len = length(pt - center),
        edge = .01;
    return smoothstep(r - edge, r, len);
}


float circle(vec2 pt, vec2 center, float r, float lw) {
    vec2 p = pt - center;
    float len = length(p);
    float hlw = lw / 2.;
    float edge = .01;
    return smoothstep(r - hlw - edge, r - hlw, len) - smoothstep(r + hlw, r + hlw + edge, len);
}

const vec3 woodAxis = normalize(vec3(1, -3, 2));
vec4 getWood(vec3 p) {
    vec3 mfp = (p + dot(p, woodAxis) * woodAxis * 15.5) * .50;
    float wood = 0.0;
    wood += abs(noise(mfp.xz * 2.) - .5);
    wood += abs(noise(mfp.xz * 12.0) - .5) / 2.0;
    wood += abs(noise(mfp.xz * 14.0) - .5) / 4.0;
    wood += abs(noise(mfp.xz * 8.0) - .5) / 8.0;
    wood /= .75 - 1.5 / 18.0;
    wood = pow(1.0 - clamp(wood, 0.0, 1.0), 5.0);
    return vec4(mix(vec3(0.62, 0.38, 0.05), vec3(0.2, 0.06, 0.01), wood), wood);
}

vec4 getRock(vec3 p) {
    vec3 mfp = (p + dot(p, vec3(0, 1, 0)) * 2.);
    float brk = 0.0;
    brk += abs(noise(mfp.xz * 2.) - .5);
    brk += abs(noise(mfp.xz * 12.0) - .5) / 2.0;
    brk = pow(1.0 - clamp(brk, 0.0, 1.0), 15.0);
    return vec4(mix(vec3(0), vec3(1), brk), brk);
}

vec3 getStripes(vec2 uv) {
    uv.yx *= r2(hash21(s_id) * 2.);
    float sd = mod(floor(uv.y * 2.5), 2.);
    return (sd < 1.) ? vec3(1.) : vec3(0.);
}

vec3 getColor(float m, in vec3 n) {
    vec3 h = vec3(0.45);

    if (m == 1.) h = vec3(0.427, 0.502, 0.514);
    if (m == 3.) h = vec3(1.000, 0.533, 0.000) * getWood(s_hp.zyx).rgb;

    if (m == 4.) {
        float hs = hash21(s_id);
        float hs2 = hash21(s_id.yx + vec2(9.));
        h = mix(hue(hs), hue(hs2), hs > .75 ? getStripes(s_hp.zy * 12.).x : 1.);
        float ck = hs > .75 ? circle(s_hp.xz - vec2(.05, .0), vec2(.0), .55) :
            circle(s_hp.xz - vec2(.5, .0), vec2(.0), .35, .25);
        float ck2 = 1. - circle(s_hp.xz - vec2(.5, .0), vec2(.0), .19);
        if (hs > .75) ck2 += circle(s_hp.xz - vec2(.5, .0), vec2(.0), .22, .01);
        h = mix(h, hue(hs2 * 11.35), ck);
        h = mix(h, hs > .75 ? vec3(1) : hue(hs2 * 11.15), ck2);
        // vec3 txt = texture(iChannel0, (s_hp.xz+vec2(-.2,.2))*vec2(2.)).rgb;
        // h = mix(h,txt,ck2);        
    }

    if (m == 5.) {
        vec3 h1 = vec3(0.012, 0.133, 0.149);
        vec3 h2 = vec3(0.055, 0.345, 0.384);
        vec3 h3 = vec3(0.004, 0.102, 0.118);
        h = mix(h1, h2, getRock(s_hp * .15 + iTime * .08).rgb);
        h = mix(h, h3, getRock(s_hp * .25 + iTime * .06).rgb);
    }
    return h;
}

// Book Of Shaders - timing functions
float linearstep(float begin, float end, float t) {
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

float easeOutCubic(float t) {
    return (t = t - 1.0) * t * t + 1.0;
}

float easeInCubic(float t) {
    return t * t * t;
}

void mainImage(out vec4 O, in vec2 F) {
    float size = 8.;
    travelSpeed = iTime * 1.3;
    trackSpeed = iTime * .85;

    float tm = mod(T * .3, 10.);

    float a1 = linearstep(0.0, 1.0, tm);
    float a2 = linearstep(1.0, 2.0, tm);
    float t1 = easeInCubic(a1);
    float t2 = easeOutCubic(a2);

    float a3 = linearstep(5.0, 6.0, tm);
    float a4 = linearstep(6.0, 7.0, tm);
    float t3 = easeInCubic(a3);
    float t4 = easeOutCubic(a4);

    float a5 = linearstep(3.0, 4.0, tm);
    float a6 = linearstep(4.0, 5.0, tm);
    float t5 = easeInCubic(a1);
    float t6 = easeOutCubic(a2);

    float a7 = linearstep(6.0, 7.0, tm);
    float a8 = linearstep(7.0, 8.0, tm);
    float t7 = easeInCubic(a3);
    float t8 = easeOutCubic(a4);

    ga1 = t1 + t2;
    ga2 = t3 + t4;
    ga3 = t5 + t6;
    ga4 = t7 + t8;

    // 
    vec2 U = (2. * F.xy - R.xy) / max(R.x, R.y);

    vec3 ro = vec3(0., 4.35, 2.65),
        lp = vec3(0, 0, 0);

    // uncomment to look around
    ro = getMouse(ro);

    vec3 cf = normalize(lp - ro),
        cp = vec3(0., 1., 0.),
        cr = normalize(cross(cp, cf)),
        cu = normalize(cross(cf, cr)),
        c = ro + cf * .675,
        i = c + U.x * cr + U.y * cu,
        rd = i - ro;

    vec3 C = vec3(0);
    vec3 FC = vec3(0.467, 0.784, 0.992) * U.y;

    ro.z += (ga1 - ga2) * size;

    // trace distance fields
    vec2 ray = marcher(ro, rd, 128);
    s_hp = g_hp;
    s_id = g_id;
    s_hsh = g_hsh;
    if (ray.x < MAX_DIST) {
        vec3 p = ro + ray.x * rd,
            n = getNormal(p, ray.x);

        vec3 lpos = ro + vec3(5., 3., -3.5);
        vec3 ll = normalize(lpos);
        vec3 h = getColor(ray.y, n);
        float diff = getDiff(p, n, lpos);
        vec3 spec = getSpec(p, n, ll, ro);
        float ao = calcAO(p, n);

        C = (h * diff + spec) * ao;

        if (ray.y == 1. || ray.y == 5.) {
            vec3 rr = reflect(rd, n);
            vec2 tr = marcher(p, rr, 98);
            s_hp = g_hp;
            s_id = g_id;
            s_hsh = g_hsh;
            if (tr.x < MAX_DIST) {
                p += rr * tr.x;
                n = getNormal(p, tr.x);
                h = getColor(tr.y, n);
                lp = normalize(lpos - p);
                diff = clamp(dot(n, lp), .01, 1.);

                C += (h * diff) * .3;

                if (tr.y == 5.) {
                    rr = reflect(rr, n);
                    tr = marcher(p, rr, 98);
                    s_hp = g_hp;
                    s_id = g_id;
                    s_hsh = g_hsh;
                    if (tr.x < MAX_DIST) {
                        p += rr * tr.x;
                        n = getNormal(p, tr.x);
                        h = getColor(tr.y, n);
                        lp = normalize(lpos - p);
                        diff = clamp(dot(n, lp), .01, 1.);

                        C += (h * diff) * .2;
                    }
                }
            }
        }
    }

    C = mix(C, FC, 1. - exp(-.00025 * ray.x * ray.x * ray.x));
    O = vec4(pow(C, vec3(0.4545)), 1.0);
}