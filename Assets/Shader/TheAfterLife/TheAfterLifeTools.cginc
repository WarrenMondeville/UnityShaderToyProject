#include "../ShaderToyTools.cginc"
// Author: Thomas Stehle
// Title: The Afterlife
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//
// After the album cover "The Afterlife" by "The Comet is Coming":
// https://www.thecometiscoming.co.uk/wp-content/uploads/2019/09/CIC_AL_A-900.png

#define PI 3.141592653589793
#define TAU 6.283185307179586

#define NUM_SAMPLES 3
#define MAX_STEPS  35
#define MAX_DIST 20.0
#define SURF_DIST 0.0001

#define GREEN_HSV vec3(157.0 / 360.0, 0.35, 0.94)
#define RED_HSV vec3(18.0 / 360.0, 0.98, 0.94)

#define INV_ID 0.0
#define CUBE_ID 1.0
#define DUNE_ID 2.0

// 1D hash for 3D input
float hash31(in vec3 p) {
    vec3 q = fract(p * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

// 2D hash for 2D input by iq
// https://www.shadertoy.com/view/XdXGW8
vec2 hash22(in vec2 p) {
    const vec2 k = vec2(0.3183099, 0.3678794);
    p = p * k + k.yx;
    return fract(16.0 * k * fract(p.x * p.y * (p.x + p.y)));
}

// 2D wave noise by iq
// https://www.shadertoy.com/view/tldSRj
float wnoise(in vec2 p, in float k, in float time)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float c = cos(0.5 * time);
    float s = sin(0.25 * time);
    mat2 rot = mat2(c, s, -s, c);
    return 0.5 + 0.5 *
        mix(mix(sin(time + k * dot(p, mul(rot, (-1.0 + 2.0 * hash22(i + vec2(0, 0)))))),
            sin(time + k * dot(p, mul(rot, (-1.0 + 2.0 * hash22(i + vec2(1, 0)))))), f.x),
            mix(sin(time + k * dot(p, mul(rot, (-1.0 + 2.0 * hash22(i + vec2(0, 1)))))),
                sin(time + k * dot(p, mul(rot, (-1.0 + 2.0 * hash22(i + vec2(1, 1)))))), f.x), f.y);
}

// 2D Fractional Brownian motion based on wave noise by iq
// https://www.shadertoy.com/view/tldSRj
float wfbm(in vec2 p, in float k, in float time) {
    mat2 rot = mat2(1.6, 1.2, -1.2, 1.6);
    float v = 0.0;
    float a = 0.5;
    const int numOctaves = 5;
    for (int i = 0; i < numOctaves; ++i) {
        v += a * wnoise(p, k, time);
        p = mul(rot, p);
        a *= 0.5;
    }
    return v;
}

mat2 rot2(in float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdBox(in vec3 p, in vec3 s) {
    p = abs(p) - s;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdPlane(in vec3 p, in float h) {
    return p.y - h;
}

float duneBump(in vec3 p) {
    return 0.1 * wnoise(p.xz, 6.0, 0.05 * iTime);
}

vec2 scene(in vec3 p) {
    vec3 boxPos = 0.075 * vec3(sin(1.1 * iTime), sin(iTime), 0.0);
    float d1 = sdBox(p - boxPos, 0.95);
    float h = 4.0 + 0.3 * (sin(0.676 * p.x) + sin(1.348 * p.z));
    h += 0.884 * duneBump(p);
    float d2 = sdPlane(p, -h);
    return (d1 < d2) ? vec2(d1, CUBE_ID) : vec2(d2, DUNE_ID);
}

vec2 castRay(in vec3 ro, in vec3 rd) {
    float t = 0.1;
    float id = INV_ID;

    for (int i = 0; i < MAX_STEPS; ++i) {
        vec3 p = ro + t * rd;
        vec2 s = scene(p);
        id = s.y;
        if (abs(s.x) < SURF_DIST * t) break;
        t += s.x;
        if (t > MAX_DIST) break;
    }

    if (t > MAX_DIST) {
        t = -1.0;
        id = INV_ID;
    }

    return vec2(t, id);
}

vec3 calcNormal(in vec3 p) {
    float t = scene(p).x;
    vec2 e = vec2(0.001, 0);
    vec3 n = t - vec3(scene(p - e.xyy).x, scene(p - e.yxy).x, scene(p - e.yyx).x);
    return normalize(n);
}

vec3 rayDir(in vec2 p, in vec3 origin, in vec3 tgt, in float z) {
    vec3 f = normalize(tgt - origin);
    vec3 r = normalize(cross(f, vec3(0, 1, 0)));
    vec3 u = cross(r, f);
    vec3 c = f * z;
    return normalize(c + p.x * r + p.y * u);
}

// Smoothstep'ed HSV to RGB conversion by iq
// https://www.shadertoy.com/view/MsS3Wc
vec3 smoothHsvToRgb(in vec3 c)
{
    vec3 rgb = abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0;
    rgb = clamp(rgb, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return c.z * mix(vec3(1.0,1.0,1.0), rgb, c.y);
}

float easeInOutSine(in float x) {
    return -0.5 * (cos(x * PI) - 1.0);
}

vec3 gradient(in vec2 p) {
    mat2 R = rot2(-0.75);
    float scale = 1.1 + 0.2 * sin(iTime);
    vec2 q = mul(R, (scale * p)) + vec2(0.5,0.5);
    vec3 col = mix(GREEN_HSV, RED_HSV, easeInOutSine(clamp(q.x + 0.15, 0.0, 1.0)));
    return smoothHsvToRgb(col);
}

// Inspired by https://www.shadertoy.com/view/lljGDt
float sun(in vec2 p, in vec2 center) {
    vec2 dir = normalize(vec2(1.0, -0.116));
    const float seedA = 36.0;
    const float seedB = 21.0;
    const float speed = 2.5;

    vec2 q = p - center;
    float angle = dot(normalize(q), dir);
    float rays = clamp(
        (0.2 + 0.15 * sin(angle * seedA + iTime * speed)) +
        (0.3 + 0.2 * cos(-angle * seedB + iTime * speed)), 0.0, 1.0);

    const float inten = 0.003;
    float atten = inten / dot(q, q);

    return rays * atten;
}

vec3 sampleScene(in vec2 uv) {
    vec3 col = vec3(0,0,0);

    // Gradient and sun
    col += gradient(uv);
    col += sun(uv, vec2(0, 0.15));

    // Cast ray
    float angle = -PI / 4.0;
    vec3 ro = 15.0 * vec3(sin(angle), 0.35, cos(angle));
    vec3 tgt = vec3(0.0, -0.25, 0.0);
    vec3 rd = rayDir(uv, ro, tgt, 2.0);
    vec2 s = castRay(ro, rd);

    // Shade scene
    if (s.x > 0.0) {
        // Hit point and normal
        vec3 p = ro + s.x * rd;
        vec3 n = calcNormal(p);

        // Cube
        if (CUBE_ID == s.y) {
            // Colors on cube surface
            const vec3 greenHsv = vec3(87.0 / 360.0, 0.96, 0.79);
            const vec3 yellowHsv = vec3(45.0 / 360.0, 0.99, 0.98);
            const vec3 orangeHsv = vec3(35.0 / 360.0, 0.98, 0.96);
            const vec3 redRgb = vec3(153, 10, 6) / 255.0;

            // Left side material
            vec2 qL = mul(rot2(-0.8), (0.6 * p.xy)) + 0.6;
            vec3 colL = mix(greenHsv, orangeHsv, easeInOutSine(clamp(qL.x, 0.0, 1.0)));
            vec3 matL = abs(n.x) * smoothHsvToRgb(colL) * pow(wfbm(1.5 * p.yz, PI, iTime + 20.0), 0.15);

            // Top side material
            // Bump shading inspired by https://www.shadertoy.com/view/Xl2XWz
            vec2 qT = mul(rot2(1.008), p.zx);
            vec3 colT = mix(greenHsv, yellowHsv, clamp(qT.x, 0.0, 1.0));
            float n1 = wfbm(1.5 * p.zx, PI, 1.0 * iTime + 10.0);
            float n2 = wfbm(1.6 * p.zx, PI, 1.01 * iTime + 10.0);
            float b1 = max(n2 - n1, 0.0) / 0.02 * 0.7071;
            float b2 = max(n1 - n2, 0.0) / 0.02 * 0.7071;
            b1 = b1 * b1 * 0.5 + pow(b1, 4.0) * 0.5;
            b2 = b2 * b2 * 0.5 + pow(b2, 4.0) * 0.5;
            float bump = clamp(0.5 + n1 * n1 * (b1 * 0.2 + b2 * 0.2 + 0.5), 0.0, 1.0);
            vec3 matT = abs(n.y) * smoothHsvToRgb(colT) * pow(bump, 0.175);

            // Right side material
            vec3 matR = abs(n.z) * redRgb * (0.1 + wfbm(0.75 * p.xy, PI, iTime));

            col = matL + matT + matR;
        }
        // Dune
        else if (DUNE_ID == s.y) {
            // Material
            vec3 mat = vec3(0.18,0.18,0.18) + 0.180 * duneBump(p);

            // Lighting
            vec3 sunDir = normalize(vec3(0.8, 0.4, 0.2));
            vec3 duneCol = mat * vec3(7.0, 4.5, 3.0) * clamp(dot(n, sunDir), 0.0, 1.0);

            // Gamma correct
            duneCol = pow(duneCol, vec3(0.4545, 0.4545, 0.4545));

            // Mix with gradient
            col = mix(col, col * duneCol, 0.35);
        }
    }

    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalize input coordinates
    vec2 uv = (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;

    // Result color
    vec3 col = vec3(0,0,0);

    // Enforce square format
    if (abs(uv.x) < 0.5 && abs(uv.y) < 0.5) {
        // Multi-sample scene
        vec2 sss = 1.0 / (float(NUM_SAMPLES) * iResolution.xy);
        for (int sy = 0; sy < NUM_SAMPLES; ++sy) {
            for (int sx = 0; sx < NUM_SAMPLES; ++sx) {
                col += sampleScene(uv + vec2(float(sx), float(sy)) * sss);
            }
        }
        col /= float(NUM_SAMPLES) * float(NUM_SAMPLES);

        // Add layer of animated dust over dune section
        vec2 off = 5.0 * vec2(0.5 + 0.5 * sin(0.2 * iTime), 0);
        float dust = 0.2 + 0.2 * wnoise(5.0 * uv - off, PI, 0.2 * iTime);
        col = mix(col, vec3(dust, dust, dust), smoothstep(-0.1, -0.75, uv.y));

        // Add layer of animated white noise
        col += 0.05 * hash31(vec3(fragCoord.xy, fract(0.001 * iTime)));

        // Vignetting
        float vig = length(uv) * 0.5;
        vig = vig * vig + 1.0;
        col *= 1.0 / (vig * vig);
    }

    // Final result
    fragColor = vec4(col, 1.0);
}
