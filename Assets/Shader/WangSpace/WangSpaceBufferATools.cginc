#include "../ShaderToyTools.cginc"
#define R           iResolution
#define T           iTime
#define M           iMouse

#define PI2         6.28318530718
#define PI          3.14159265358

#define MINDIST     .0005
#define MAXDIST     100.

#define r2(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define s2(a, b) 1. - smoothstep(0., a, b)

float hash21(vec2 p) { return fract(sin(dot(p, vec2(27.609, 57.583))) * 43758.5453); }

void getMouse(vec3 ro) {
    float x = M.xy == vec2(0,0) ? .0 : -(M.y / R.y * 1. - .5) * PI;
    float y = M.xy == vec2(0,0) ? .0 : (M.x / R.x * 1. - .5) * PI;
    ro.zy = mul(ro.zy, r2(x));
    ro.xz = mul(ro.xz, r2(y));
}

//http://mercury.sexy/hg_sdf/
float vmax(vec3 v) { return max(max(v.x, v.y), v.z); }
float fBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, vec3(0,0,0))) + vmax(min(d, vec3(0,0,0))) - r;
}
//@iq
float sBox(vec2 p, vec2 b, float r) {
    p = max(abs(p) - b + r, 0.);
    return length(p) - r;
}
float sdCyl(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

//globals//
float g_dk, s_dk, g_df, s_df, g_hsh, s_hsh, hgt;
vec3 g_hp, s_hp, g_id, s_id;
float ft, glow;
//@Shane https://www.shadertoy.com/view/ttsXW7
//method for edge/decode-encode and
float edges(vec2 ip, vec2[4] ep, float rnd) {
    float id = 0.;
    for (int i = 0; i < 4; i++) id += hash21(ip + ep[i]) > rnd ? exp2(float(i)) : 0.;
    return id;
}
//tile and sdf constants   
const float tscale = 1.;
const float ts = tscale * .8;
const float hlf = tscale / 2.;
const vec2[4] eps = vec2[4](vec2(-.5, 0), vec2(0, .5), vec2(.5, 0), vec2(0, -.5));
const vec2[4] tps = vec2[4](vec2(-ts, 0), vec2(0, ts), vec2(ts, 0), vec2(0, -ts));
const vec2 poleSize = vec2(.065, .575);
const vec2 poles = poleSize * .2;
const vec2 sphere = poleSize * .55;

vec2 map(vec3 p) {
    vec2 res = vec2(1e5, 0.);
    p -= vec3(0, 0, ft);
    vec3 q = p;
    vec3 p2 = q;
    vec3 qid = floor((q + hlf) / tscale);
    q.xz = mod(q.xz + hlf, tscale) - hlf;

    vec2[4] cp = eps;
    float id = edges(qid.xz, eps, .525);
    float xh = hash21(qid.xz) * .112;
    float fx = .095 + .085 * sin(p2.x * 1.72);
    float poleHgt = poleSize.y - fx;
    vec3 bl = vec3(hlf, 2.5, .15);
    vec2 dl = bl.xz * .8;
    vec3 boxLine = vec3(hlf * .9, 2.5, .25);

    float d3 = 1e5;
    float d4 = 1e5;
    float d4a = 1e5;
    float d5 = 1e5;
    float ln = 1e5;

    // decode each binary digit.
    vec4 bits = mod(floor(id / vec4(1, 2, 4, 8)), 2.);
    int iNum = 0;

    for (int i = 0; i < 4; i++) {
        if (bits[i] > .5) cp[iNum++] = eps[i];
    }

    float hsh;
    int bend = (iNum == 2 && length(cp[0] - cp[1]) < .99) ? 1 : 0;

    for (int i = 0; i < 4; i++) {
        if (bits[i] > .5) {
            hsh += .25;
            if (bend == 0) {

                vec3 nq = q - vec3(tps[i].x / 3.65, 3., tps[i].y / 3.65);
                vec3 lq = q - vec3(tps[i].x / 2.75, 3., tps[i].y / 2.75);

                d3 = min(fBox(nq, boxLine, .05), d3);
                d5 = min(fBox(vec3(nq.z, abs(nq.y + 2.2), nq.x) - vec3(0, .1, 0), vec3(boxLine.x, .0215 + fx * .175, boxLine.z), .025), d5);
                ln = min(ln, sBox(lq.xz, bl.xz * .8, .0));

                vec3 dq = q - vec3(tps[i].x / 2., .75, tps[i].y / 2.);

                if (abs(tps[i].x) > 0.) dq.z = abs(dq.z) - .4;
                if (abs(tps[i].y) > 0.) dq.x = abs(dq.x) - .4;

                d4 = min(sdCyl(dq, poleSize.x, poleSize.y), d4);
                d4a = min(sdCyl(dq, poles.x, poleHgt), d4a);
                d4a = min(length(dq - vec3(0, poleHgt, 0)) - sphere.x, d4a);
            }
        }

        bl = bl.zyx;
        boxLine = boxLine.zyx;
    }

    if (iNum == 2 && bend == 1) {
        vec2 pnt;
        pnt.x = abs(cp[0].x) > abs(cp[1].x) ? cp[0].x : cp[1].x;
        pnt.y = abs(cp[0].y) > abs(cp[1].y) ? cp[0].y : cp[1].y;
        hsh += 1.25;
        d3 = min(fBox(q - vec3(pnt.x * .4, 3., 0.), boxLine, .05), d3);
        d3 = min(fBox(q - vec3(0., 3., pnt.y * .4), boxLine.zyx, .05), d3);

        ln = min(ln, sBox(q.xz - vec2(pnt.x * .565, 0.), dl, .0));
        ln = min(ln, sBox(q.xz - vec2(0., pnt.y * .565), dl.yx, .0));
        vec3 dq;

        if (abs(pnt.x) > 0.) {
            dq = q - vec3(pnt.x / 1.25, .75, 0.);
            dq.z = abs(dq.z) - .4;
            d4 = min(sdCyl(dq, poleSize.x, poleSize.y), d4);
            d4a = min(sdCyl(dq, poles.x, poleHgt), d4a);
            d4a = min(length(dq - vec3(0, poleHgt, 0)) - sphere.x, d4a);
        }

        if (abs(pnt.y) > 0.) {
            dq = q - vec3(0., .75, pnt.y / 1.25);
            dq.x = abs(dq.x) - .4;
            d4 = min(sdCyl(dq, poleSize.x, poleSize.y), d4);
            d4a = min(sdCyl(dq, poles.x, poleHgt), d4a);
            d4a = min(length(dq - vec3(0, poleHgt, 0)) - sphere.x, d4a);
        }

    }

    g_df = ln;
    ln = abs(ln - .05) - .025;
    g_dk = ln;
    if (d4a < res.x) {
        res = vec2(d4a * 1.15, 2.);
        g_hp = q;
        g_id = qid;
        g_hsh = hsh;
    }

    vec2 box = vec2((hlf * .945), 1.175 - (fx)+(xh));
    float d2 = max(fBox(q, box.xyx, .02), -d5);
    d2 = max(d2, -d3);
    d2 = max(d2, -d4);
    if (d2 < res.x) {
        res = vec2(d2 * 1.15, 1.);
        g_hp = q;
        g_id = qid;
        g_hsh = hsh;
    }

    float d = (p.y - .455);
    if (d < res.x) {
        res = vec2(d, 3.);
        g_hp = p;
    }

    return res;
}

vec2 marcher(vec3 ro, vec3 rd, int maxstep) {
    float d = .0,
        m = -1.;
    for (int i = 0;i < maxstep;i++) {
        vec3 p = ro + rd * d;
        vec2 t = map(p);
        if (abs(t.x) < d * MINDIST || d > MAXDIST)break;
        d += i < 64 ? i < 32 ? t.x * .25 : t.x * .75 : t.x;
        m = t.y;
    }
    return vec2(d, m);
}

// Tetrahedron technique @iq
// https://www.iquilezles.org/www/articles/normalsSDF
vec3 getNormal(vec3 p, float t) {
    float e = t * MINDIST;
    vec2 h = vec2(1., -1.) * .5773;
    return normalize(h.xyy * map(p + h.xyy * e).x +
        h.yyx * map(p + h.yyx * e).x +
        h.yxy * map(p + h.yxy * e).x +
        h.xxx * map(p + h.xxx * e).x);
}

float getDiff(vec3 p, vec3 n, vec3 lpos) {
    vec3 l = normalize(lpos - p);
    float dif = clamp(dot(n, l), .01, 1.);
    float shadow = marcher(p + n * .01, l, 72).x;
    if (shadow < length(p - lpos)) dif *= .2;
    return dif;
}

//@Shane AO
float calcAO(in vec3 p, in vec3 n) {
    float sca = 4.5, occ = 0.;
    for (int i = 0; i < 5; i++) {
        float hr = float(i + 1) * .0029 / .27;
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

vec3 stripes(vec2 uv) {
    uv.y -= tan(radians(-45.)) * uv.x;
    float sd = mod(floor(uv.y * 12.5), 2.);
    return (sd < 1.) ? vec3(1.) : vec3(0.);
}

float circle(vec2 pt, vec2 center, float r, float lw) {
    float len = length(pt - center),
        hlw = lw / 2., edge = .05;
    return smoothstep(r - hlw - edge, r - hlw, len) - smoothstep(r + hlw, r + hlw + edge, len);
}

float circles(vec2 uv) {
    vec2 dv = uv * 8.;
    float cir = circle(fract(dv), vec2(0.5), .29, .06);
    cir += circle(fract(dv), vec2(0.5), .45, .06);
    return 1. - cir;
}
//@iq https://iquilezles.org/www/articles/palettes
vec3 hue(float t) {
    vec3 c = vec3(.95, .97, .98),
        d = vec3(.17, 0.35, 0.64),
        a = vec3(.725),
        b = vec3(.475);
    return a + b * cos(PI2 * t * (c * d));
}
// Tri-Planar blending function Ryan Geiss
// https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D t, in vec3 p, in vec3 n) {
    n = max(abs(n), .001);
    n /= dot(n, vec3(1));
    vec3 tx = texture(t, p.yz).xyz;
    vec3 ty = texture(t, p.zx).xyz;
    vec3 tz = texture(t, p.xy).xyz;
    return (tx * tx * n.x + ty * ty * n.y + tz * tz * n.z);
}

vec3 getColor(float m, vec3 n) {
    vec3 h = vec3(0);
    if (m == 1.) {
        vec3 nhp = s_hp * .75;
        float tn = tex3D(iChannel0, s_hp, n).r;
        float tx = tex3D(iChannel0, s_hp + vec3(.5), n).r;
        float x = mix(0., .5, tn);
        x = mix(x, 1., tx);
        h = hue(s_hsh * 1.25) * x;
    }
    if (m == 2.) h = vec3(.1);
    if (m == 3.) {
        float tn = tex3D(iChannel0, s_hp, n).r;
        h = hue(2.);
        float px = 1. / max(R.x, R.y);
        float bline = smoothstep(px, -px, s_dk);
        float pth = smoothstep(px, -px, s_df) * 1.5;
        h = mix(h * tn, hue(2.), bline * stripes(s_hp.xz));
        h = mix(h, hue(3.25), pth * circles(s_hp.xz));
    }
    return h;
}

//camera setup
vec3 camera(vec3 lp, vec3 ro, vec2 uv) {
    vec3 f = normalize(lp - ro),
        r = normalize(cross(vec3(0, 1, 0), f)),
        u = normalize(cross(f, r)),
        c = ro + f * .85,
        i = c + uv.x * r + uv.y * u,
        rd = i - ro;
    return rd;
}

void mainImage(out vec4 O, in vec2 F) {
    ft = T * .45;
    float zoom = 2. + 2. * sin(T * .1);
    // pixel screen coordinates
    vec2 uv = (F.xy - R.xy * 0.5) / max(R.x, R.y);
    vec3 C = vec3(0.),
        FC = vec3(0.9);
    vec3 lp = vec3(0., 0., 0.),
        ro = vec3(3.5, 3.5 + zoom, 3.);

    //ro = getMouse(ro);
    vec3 rd = camera(lp, ro, uv);

    vec2 t = marcher(ro, rd, 164);
    s_hp = g_hp;
    s_id = g_id;
    s_hsh = g_hsh;
    s_dk = g_dk;
    s_df = g_df;
    float d = t.x,
        m = t.y;

    float x = M.xy == vec2(0) ? -.85 : -(M.y / R.y * 1. - .5) * PI;
    float y = M.xy == vec2(0) ? .45 : (M.x / R.x * 1. - .5) * PI;

    // if visible 
    if (m > 0.) {
        // step next point
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p, d);

        vec3 lpos = vec3(5., 11.5, .0) + vec3(x * 6., 0, y * 6.);
        vec3 ll = normalize(lpos);
        vec3 h = getColor(m, n);
        float diff = getDiff(p, n, lpos);
        vec3 spec = m != 3. ? getSpec(p, n, ll, ro) : vec3(0.);
        float ao = calcAO(p, n);

        C = (h * diff + spec) * ao;
    }

    C = mix(C, FC, 1. - exp(-0.000075 * t.x * t.x * t.x));
    O = vec4(C, 1.0);
}
