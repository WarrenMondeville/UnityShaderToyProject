#include "../ShaderToyTools.cginc"

#define MAX_STEPS 50

// undef to disable hole, then parameter s.w not needed
// #define CONVEX

// sdUberprim with precomputed constants
float sdUnterprim(vec3 p, vec4 s, vec3 r, vec2 ba, float sz2) {
    vec3 d = abs(p) - s.xyz;
    float q = length(max(d.xy, 0.0)) + min(0.0, max(d.x, d.y)) - r.x;
    // hole support: without this line, all results are convex
#ifndef CONVEX    
    q = abs(q) - s.w;
#endif

    vec2 pa = vec2(q, p.z - s.z);
    vec2 diag = pa - vec2(r.z, sz2) * clamp(dot(pa, ba), 0.0, 1.0);
    vec2 h0 = vec2(max(q - r.z, 0.0), p.z + s.z);
    vec2 h1 = vec2(max(q, 0.0), p.z - s.z);

    return sqrt(min(dot(diag, diag), min(dot(h0, h0), dot(h1, h1))))
        * sign(max(dot(pa, vec2(-ba.y, ba.x)), d.z)) - r.y;
}

// s: width, height, depth, thickness
// r: xy corner radius, z corner radius, bottom radius offset
float sdUberprim(vec3 p, vec4 s, vec3 r) {
    // these operations can be precomputed
    s.xy -= r.x;
#ifdef CONVEX  
    r.x -= r.y;
#else
    r.x -= s.w;
    s.w -= r.y;
#endif
    s.z -= r.y;
    vec2 ba = vec2(r.z, -2.0 * s.z);
    return sdUnterprim(p, s, r, ba / dot(ba, ba), ba.y);
}

// example parameters
#define SHAPE_COUNT 9.0
void getfactor(int i, out vec4 s, out vec3 r) {
    //i = 4;
    if (i == 0) { // cube
        s = vec4(1.0, 1.0, 1.0, 1.0);
        r = vec3(0.0, 0.0, 0.0);
    }
    else if (i == 1) { // cylinder
        s = vec4(1.0, 1.0, 1.0, 1.0);
        r = vec3(1.0, 0.0, 0.0);
    }
    else if (i == 2) { // cone
        s = vec4(0.0, 0.0, 1.0, 1.0);
        r = vec3(0.0, 0.0, 1.0);
    }
    else if (i == 3) { // pill
        s = vec4(1.0, 1.0, 2.0, 1.0);
        r = vec3(1.0, 1.0, 0.0);
    }
    else if (i == 4) { // sphere
        s = vec4(1.0, 1.0, 1.0, 1.0);
        r = vec3(1.0, 1.0, 0.0);
    }
    else if (i == 5) { // pellet
        s = vec4(1.0, 1.0, 0.25, 1.0);
        r = vec3(1.0, 0.25, 0.0);
    }
    else if (i == 6) { // torus
        s = vec4(1.0, 1.0, 0.25, 0.25);
        r = vec3(1.0, 0.25, 0.0);
    }
    else if (i == 7) { // pipe
        s = vec4(1.0, 1.0, 1.0, 0.25);
        r = vec3(1.0, 0.1, 0.0);
    }
    else if (i == 8) { // corridor
        s = vec4(1.0, 1.0, 1.0, 0.25);
        r = vec3(0.1, 0.1, 0.0);
    }
}

void doCamera(out vec3 camPos, out vec3 camTar, in float time, in float mouseX)
{
    float an = 1.5 + sin(time * 0.1) * 0.7;
    camPos = vec3(4.5 * sin(an), 2.0, 4.5 * cos(an));
    camTar = vec3(0.0, 0.0, 0.0);
}

vec3 doBackground(void)
{
    return vec3(0.0, 0.0, 0.0);
}

// polynomial smooth min (k = 0.1);
float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float doobject(vec3 p, float k) {
    float u = smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, fract(k)));
    int s1 = int(mod(k, SHAPE_COUNT));
    int s2 = int(mod(k + 1.0, SHAPE_COUNT));

    vec4 sa, sb;
    vec3 ra, rb;
    getfactor(s1, sa, ra);
    getfactor(s2, sb, rb);

    return  sdUberprim(p.zyx, mix(sa, sb, u), mix(ra, rb, u));
}

bool interior;

float doModel(vec3 p) {
    float k = iTime * 0.5;
    float d = doobject(p - vec3(0.0, 0.0, -0.5), k);
    float d2 = doobject(p - vec3(0.0, 0.0, 0.5), k + 1.0);
    if (interior)
        d = min(d, d2);
    else
        d = smin(d, d2, 0.4);

    return d;
}

float calcIntersection(in float t, in vec3 ro, in vec3 rd, vec2 pixel, float bias, inout int steps)
{
    const float maxd = 20.0;           // max trace distance
    float aperture = 0.7071067811866 * max(pixel.y, pixel.x);        // aperture of cone
    float C = sqrt(aperture * aperture + 1.0);
    // radius of sphere at t=1
    float R = aperture / C;
    // constant adjustment factor for t so that the cone sphere touches the distance radius
    float A = C / (C + bias * aperture);
    // for a better demo of how the above factors work, see https://www.shadertoy.com/view/4lfBWH

    float res = -1.0;
    float tc = (bias > 0.0) ? 0.0 : 1.0;
    t = t * C;
    for (int i = 0; i < MAX_STEPS; i++) {
        steps = steps + 1;
        float limit = bias * R * t;
        // add small bias to reduce iteration count
        limit += 1e-03 * t;
        float h = doModel(ro + rd * t);
        t = (t + h) * A;
        if ((h <= limit) || (t > maxd)) {
            break;
        }
    }

    if (t < maxd) res = t;
    return res / C;
}

vec3 calcNormal(in vec3 pos)
{
    const float eps = 0.002;             // precision of the normal computation

    const vec3 v1 = vec3(1.0, -1.0, -1.0);
    const vec3 v2 = vec3(-1.0, -1.0, 1.0);
    const vec3 v3 = vec3(-1.0, 1.0, -1.0);
    const vec3 v4 = vec3(1.0, 1.0, 1.0);

    return normalize(v1 * doModel(pos + v1 * eps) +
        v2 * doModel(pos + v2 * eps) +
        v3 * doModel(pos + v3 * eps) +
        v4 * doModel(pos + v4 * eps));
}

mat3 calcLookAtMatrix(in vec3 ro, in vec3 ta, in float roll)
{
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(sin(roll), cos(roll), 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

bool dorender(inout float dist, inout int steps, out vec3 position, in vec2 p, in vec2 pixel, in float bias)
{
    //-----------------------------------------------------
    // camera1
    //-----------------------------------------------------
    // camera movement
    vec3 ro, ta;
    doCamera(ro, ta, iTime, 0.0);

    // camera matrix
    mat3 camMat = calcLookAtMatrix(ro, ta, 0.0);  // 0.0 is the camera roll

    // create view ray
    vec3 rd = normalize(mul(vec3(p.xy, 2.0), camMat)); // 2.0 is the lens length

    //-----------------------------------------------------
    // render
    //-----------------------------------------------------

    vec3 col = doBackground();

    // raymarch
    float t = calcIntersection(dist, ro, rd, pixel, bias, steps);
    dist = t;
    if (t > -0.5)
    {
        // geometry
        position = ro + t * rd;
        return true;
    }
    return false;
}

vec3 hue2rgb(float hue) {
    return clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

// maps n=0 to blue, n=1 to red, n=0.5 to green
vec3 normhue(float n) {
    return hue2rgb((1.0 - clamp(n, 0.0, 1.0)) * 0.66667);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
    vec2 c0 = vec2(-2.0, -2.0);
    vec2 c1 = vec2(2.0, 2.0);
    const int N = 9;
    vec3 color = vec3(0.1, 0.1, 0.1);
    int steps = 0;
    float dist = 0.0;
    for (int i = 0; i <= N; ++i) {
        vec2 c = (c0 + c1) * 0.5;
        vec2 h = (c1 - c0) * 0.5;
        if (p.x < c.x) {
            c1.x = c.x;
        }
        else {
            c0.x = c.x;
        }
        if (p.y < c.y) {
            c1.y = c.y;
        }
        else {
            c0.y = c.y;
        }
        vec2 u = vec2(c0.x, c1.x);
        vec2 v = vec2(c0.y, c1.y);

        vec2 center = vec2(u.y + u.x, v.y + v.x) * 0.5;
        vec2 radius = vec2(u.y - u.x, v.y - v.x) * 0.5;

        vec3 pos;
        bool outer_hit = dorender(dist, steps, pos, center, radius, 1.0);
        float dist2 = dist;
        bool inner_hit = dorender(dist2, steps, pos, center, radius, -1.0);
        if (!outer_hit || inner_hit || (i == N)) {
            color = normhue(float(steps) / float(MAX_STEPS * N));
            float q = abs(max(abs(p.x - center.x), abs(p.y - center.y)) - radius.x) - 0.0001;
            q = clamp(q * 200.0, 0.0, 1.0);
            color *= vec3(q, q, q);
            break;
        }
    }
    fragColor = vec4(color, 1.0);
}