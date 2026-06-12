#include "../ShaderToyTools.cginc"
// Author: Thomas Stehle
// Title: Down in the Weeds
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//
// After the album cover "Down in the weeds where the world once was" by "Bright Eyes":

const float PI = 3.141592653589793;

mat2 rot2(in float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

// 1D hash for 1D input by David Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash11(in float p) {
    p = fract(p * 0.011);
    p *= p + 7.5;
    p *= p + p;
    return fract(p);
}

// 1D hash for 2D input by David Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash21(in vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.13);
    p3 += dot(p3, p3.yzx + 3.333);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D hash for 2D input by iq
// https://www.shadertoy.com/view/XdXGW8
vec2 hash22(in vec2 p) {
    const vec2 k = vec2(0.3183099, 0.3678794);
    p = p * k + k.yx;
    return fract(16.0 * k * fract(p.x * p.y * (p.x + p.y)));
}

// 1D hash for 3D input
float hash31(in vec3 p) {
    vec3 q = fract(p * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

// Smooth maximum by iq
// http://iquilezles.org/www/articles/smin/smin.htm
float smax(in float a, in float b, in float k) {
    float h = max(k - abs(a - b), 0.0);
    return max(a, b) + h * h * 0.25 / k;
}

// Smooth HSV to RGB conversion by iq
vec3 smoothHsvToRgb(in vec3 c)
{
    vec3 rgb = abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0;
    rgb = clamp(rgb, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0,1.0,1.0), rgb, c.y);
}

// Basic noise by iq
// https://www.shadertoy.com/view/3sd3Rs
float bnoise(in float x) {
    // setup    
    float i = floor(x);
    float f = fract(x);
    float s = sign(fract(x / 2.0) - 0.5);

    // use some hash to create a random value k in [0..1] from i
    float k = fract(i * 0.1731);

    // quartic polynomial
    return s * f * (f - 1.0) * ((16.0 * k - 4.0) * f * (f - 1.0) - 1.0);
}

// 2D simplex noise by iq
// https://www.shadertoy.com/view/Msf3WH
float snoise(in vec2 p)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2
    const float K2 = 0.211324865; // (3-sqrt(3))/6
    vec2  i = floor(p + (p.x + p.y) * K1);
    vec2  a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    vec2  o = vec2(m, 1.0 - m);
    vec2  b = a - o + K2;
    vec2  c = a - 1.0 + 2.0 * K2;
    vec3  h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3  n = h * h * h * h * vec3(
        dot(a, -1.0 + 2.0 * hash22(i + 0.0)),
        dot(b, -1.0 + 2.0 * hash22(i + o)),
        dot(c, -1.0 + 2.0 * hash22(i + 1.0)));
    return 0.5 + 0.5 * dot(n, vec3(70.0,70.0,70.0));
}

// 1D fractional Brownian motion based on basic noise by iq
// https://www.shadertoy.com/view/3sd3Rs
float bfbm(in float x) {
    float n = 0.0;
    float s = 1.0;
    const int iterations = 5;
    for (int i = 0; i < iterations; ++i) {
        n += s * bnoise(x);
        s *= 0.5;
        x *= 2.0;
        x += 0.131;
    }
    return n;
}

float cone(in vec2 p) {
    float upper = sin(2.1 * p.y + -0.35);
    float lower = 0.1;
    return smax(upper, lower, 1.0);
}

float branchLayer(in vec2 p, in float idx) {
    const float ncols = 8.5;                // Number of columns
    vec2 q = vec2(ncols * p.x, p.y + 13.0); // Column global coords
    vec2 uv = vec2(fract(q.x) - 0.5, q.y);  // Column local coords
    float id = floor(q.x) + idx;            // Column id

    // Modulate amplitude to be stronger near the top
    float amp = 0.15 + 0.25 * smoothstep(-0.5, -0.3, p.y);

    // Animate amplitude
    amp *= sin(1.5 * iTime + idx + id);

    // Modulate frequency to be column-dependent and stronger near the top
    float freq = 2.0 * hash11(id) * uv.y;

    // Animate frequency
    freq *= 0.5 + (0.5 + 0.5 * sin(0.1 * iTime + idx + id));

    // Modulate branch width
    float w = 0.005 + 0.025 * hash11(id);

    // 1D noise profile
    float x = amp * bfbm(freq);
    return 1.0 - smoothstep(w - 0.01, w + 0.01, abs(uv.x - x));
}

vec3 branches(in vec2 p) {
    vec3 col = vec3(0,0,0);

    // Branch colors
    const vec3 bcolor1 = vec3(183, 188, 155) / 255.0;
    const vec3 bcolor2 = vec3(90, 104, 129) / 255.0;

    // Branch layers
    const int nlayers = 8;
    const float lstep = 1.0 / float(nlayers);
    for (int i = 1; i <= nlayers; ++i) {
        float idx = float(i); 					           // Layer index
        vec3 lcolor = mix(bcolor1, bcolor2, idx * lstep);  // Layer color
        float off = 0.005 * sin(idx + iTime);              // Layer-dependent, animated horizontal offset
        col = mix(col, lcolor, branchLayer(vec2(p.x + 5.0 * idx + off, p.y), idx));
    }

    return col;
}

vec3 sun(in vec2 p, in vec2 origin) {
    vec3 col = vec3(0,0,0);

    // Local coordinates
    vec2 q = p - origin;

    // Animate
    q.x += 0.005 * sin(20.0 * q.y + iTime);

    // Distance to center
    const float rmax = 0.1;
    float d = length(q);

    // Early exit in case we missed the sun
    if (d > rmax) return vec3(0,0,0);

    // Disk colors
    const vec3 innerHsv = vec3(70.0 / 360.0, 0.696, 0.99);
    const vec3 outerHsv = vec3(0.0 / 360.0, 1.0, 0.98);

    // Disks
    const int ndisks = 8;
    const float dstep = 1.0 / float(ndisks);
    float mask = step(d, rmax);
    float w = mask * float(ndisks) * d / rmax;
    float u = floor(w);

    // Disk shape animation
    float an = atan(q.x, q.y);
    float freq = 2.0 * hash11(u) * an;
    float shift = 1.5 * (-0.5 + hash11(10.0 * u * dstep)) * iTime;
    w += 0.2 * bfbm(freq + shift);

    // Disk components
    u = floor(w);
    float f = fract(w);

    // Disk color
    col = mask * mix(innerHsv, outerHsv, (u + 1.0) * dstep);
    col = smoothHsvToRgb(col);

    // Shadow
    float sha = pow(f, 0.25);
    vec2 qr = mul(rot2(-0.5) , q);
    col *= (1.0 + smoothstep(0.2, 0.0, qr.x - qr.y + 0.1)) * sha;

    // Bright spot in center
    const float inten = 0.0003;
    float spot = inten / (d * d);

    return col + spot;
}

// Oriented box by iq
// https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdOrientedBox(in vec2 p, in vec2 a, in vec2 b, float th)
{
    float l = length(b - a);
    vec2  d = (b - a) / l;
    vec2  q = p - (a + b) * 0.5;
    q = mul(mat2(d.x, -d.y, d.y, d.x) , q);
    q = abs(q) - vec2(l, th) * 0.5;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

float sdLimb(in vec2 p,
    in vec2 from,
    in vec2 to,
    in float rmin,
    in float rrange,
    in float freq,
    in float off) {
    vec2 d = (to - from) / length(to - from);
    vec2 q = p - 0.5 * (from + to);
    q = mul(mat2(d.x, -d.y, d.y, d.x) , q);
    float r = rmin + rrange * sin(freq * q.x + off);
    return sdOrientedBox(p, from, to, 0.0) - r;
}

float body(in vec2 p, in vec2 pos) {
    float t = 1.0;

    // Legs
    {
        const float rmin = 0.0035;
        const float rrange = 0.001;
        const float freq = 80.0;
        const float off = 0.87;
        vec2 a1 = pos + vec2(-0.0125, -0.076);
        vec2 b1 = pos + vec2(-0.0025, 0.0);
        vec2 a2 = pos + vec2(0.0125, -0.075);
        vec2 b2 = pos + vec2(0.0025, 0.0);
        t = min(t, sdLimb(p, a1, b1, rmin, rrange, freq, off));
        t = min(t, sdLimb(p, a2, b2, rmin, rrange, freq, off));
    }

    // Torso
    {
        const float rmin = 0.008;
        const float rrange = 0.0005;
        const float freq = 120.0;
        const float off = 0.78;
        vec2 a = pos + vec2(0.0, -0.02);
        vec2 b = pos + vec2(0.0, 0.03);
        t = min(t, sdLimb(p, a, b, rmin, rrange, freq, off));
    }

    // Arms
    {
        const float rmin = 0.001;
        const float rrange = 0.001;
        const float freq = 100.0;
        const float off = 2.6;
        vec2 a1 = pos + vec2(0.0, 0.030);
        vec2 b1 = pos + vec2(0.05, 0.015);
        vec2 a2 = pos + vec2(0.0, 0.01);
        vec2 b2 = pos + vec2(0.045, -0.005);
        t = min(t, sdLimb(p, a1, b1, rmin, rrange, freq, off));
        t = min(t, sdLimb(p, a2, b2, rmin, rrange, freq, off));
    }

    // Head
    {
        const float rmin = 0.006;
        const float rrange = 0.002;
        const float freq = 200.0;
        const float off = 1.7;
        vec2 a = pos + vec2(0.0, 0.0425);
        vec2 b = pos + vec2(0.0, 0.055);
        t = min(t, sdLimb(p, a, b, rmin, rrange, freq, off));
    }

    return t;
}

vec3 peopleLayer(in vec2 p, in vec3 baseCol, in vec3 highCol, in float idx) {
    vec3 col = vec3(0,0,0);

    // Deform coordinates
    vec2 q = p;
    q.x /= pow(q.y + 0.75, 1.2); // Gears people towards the sun
    q.y /= q.y + 0.8;
    q.y += 0.05 * iTime;

    // Grid components
    const float grid = 5.0;
    q *= grid;
    vec2 gv = fract(q) - 0.5;
    vec2 id = floor(q) + idx;

    // Deform grid
    float angle = PI - 1.0 + 2.0 * hash21(id) + 0.5 * iTime;
    float scale = 0.3 + 0.05 * hash21(id + 10.0);
    gv.x *= (hash21(id + 20.0) > 0.5) ? 1.0 : -1.0; // Randomly flip
    gv.x += 0.1 * sin(10.0 * (gv.y + 0.5));         // Horiz. deformation
    gv *= scale;                                    // Scaling
    gv = mul(rot2(angle) , gv);                          // Rotation

    // Determine body color
    float blend =
        step(0.2, hash21(id + 30.0)) *  // Stear likelihood for highlight toward bottom
        smoothstep(0.2, 0.1, p.y) *     // Blend in highlight near top...
        smoothstep(0.2, 0.1, abs(p.x)); // ...and center
    vec3 bodyCol = mix(baseCol, highCol, blend);

    // Bodies
    vec2 pos = -0.05 + 0.1 * hash22(id);
    col += bodyCol * (1.0 - smoothstep(0.0, 0.0025, body(gv, pos)));

    // Debug grid
    //col += vec3(step(0.49 * scale, abs(gv.x)) + step(0.49 * scale, abs(gv.y)));

    return col;
}

vec3 people(in vec2 p) {
    vec3 col = vec3(0,0,0);

    const vec3 bcol1 = vec3(194.0 / 360.0, 0.99, 0.5);
    const vec3 bcol2 = vec3(182.0 / 360.0, 0.34, 0.9);
    const vec3 hcol1 = vec3(1.6 / 360.0, 0.74, 0.8);
    const vec3 hcol2 = vec3(15.0 / 360.0, 1.00, 1.0);

    const int nlayers = 11;
    const float lstep = 1.0 / float(nlayers);
    for (int i = 1; i <= nlayers; ++i) {
        float idx = float(i);
        vec2 off = -0.125 + 0.25 * vec2(hash11(idx), hash11(2.0 * idx));
        vec3 baseCol = smoothHsvToRgb(mix(bcol1, bcol2, idx * lstep));
        vec3 highCol = smoothHsvToRgb(mix(hcol1, hcol2, idx * lstep));
        col += peopleLayer(p + off, baseCol, highCol, idx);
    }

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Normalize input coordinates such that (0, 0) is in the center
    vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    // Output color
    vec3 col = vec3(0,0,0);

    // Starfield layer
    float rnd = hash21(0.7 * fragCoord.xy);
    col += 0.8 * step(0.998, rnd) * snoise(25.0 * uv + sin(iTime));

    // Branches layer
    float mask = smoothstep(0.02, 0.1, abs(uv.x) - cone(uv) + 0.05);
    if (mask > 0.0) col += branches(uv) * mask;

    // Super-sample sun layer
    const vec2 sunPos = vec2(0.0, -0.325);
    const int ns = 3;
    vec2 sstep = 1.0 / (float(ns) * iResolution.xy);
    vec3 sunCol = vec3(0,0,0);
    for (int dy = 0; dy < ns; ++dy) {
        for (int dx = 0; dx < ns; ++dx) {
            sunCol += sun(uv + vec2(float(dx), float(dy)) * sstep, sunPos);
        }
    }
    col += sunCol / float(ns * ns);

    // People layer
    mask = smoothstep(-0.35, -0.3, uv.y) *
        smoothstep(0.1, 0.0, abs(uv.x) - cone(uv) + 0.075);
    if (mask > 0.0) col += people(uv) * mask;

    // Illumination from left and right
    const vec3 colorL = vec3(9, 79, 143) / 255.0;
    const vec3 colorR = vec3(249, 187, 2) / 255.0;
    col = mix(col, colorL, clamp(-0.55 * uv.x, 0.0, 1.0));
    col = mix(col, colorR, clamp(0.35 * uv.x, 0.0, 1.0));

    // Add layer of animated white noise
    col += 0.05 * hash31(vec3(fragCoord.xy, fract(0.001 * iTime)));

    // Final result
    fragColor = vec4(col, 1.0);
}
