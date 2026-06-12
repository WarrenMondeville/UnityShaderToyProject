#include "../ShaderToyTools.cginc"

#define LINE_THICKNESS 0.002

#define SHOW_DISTANCE false

#define PI 3.1415

mat2 rot(float r)
{
    float s = sin(r), c = cos(r);
    return mat2(c, -s, s, c);
}

vec2 closestPointLine(vec2 a, vec2 b, vec2 p)
{
    vec2 ab = b - a;
    float dist = dot(p - a, ab) / dot(ab, ab);
    if (dist < 0.0) { return a; }
    else if (dist > 1.0) { return b; }
    else { return a + (ab * dist); }
}

float sliderPointLine(vec2 a, vec2 b, vec2 p)
{
    vec2 ab = b - a;
    return clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
}

float distToLine(vec2 a, vec2 b, vec2 p) { return length(p - closestPointLine(a, b, p)); }

vec3 worldToView(vec3 p)
{
    p.xz = mul(p.xz, -rot(iTime * PI * 0.5)); // Rotate World Y
    p.yz = mul(p.yz, -rot(sin(iTime * PI * 0.5) * PI * 0.1)); // Rotate World X
    p -= vec3(0.0, 0.0, 2.0); // Cam Pos
    p.xyz /= p.z; // Smaller as it gets further away.
    return p;
}

float distToBoxLines(vec3 p, vec3 s, vec2 uv)
{
    s *= 0.5;
    vec3 bmin = p - s; // Left down back   (box min pos)
    vec3 bmax = p + s; // Right up forward (box max pos)
    vec3 ldb = worldToView(bmin);
    vec3 rdb = worldToView(vec3(bmax.x, bmin.y, bmin.z));
    vec3 lub = worldToView(vec3(bmin.x, bmax.y, bmin.z));
    vec3 rub = worldToView(vec3(bmax.x, bmax.y, bmin.z));
    vec3 ldf = worldToView(vec3(bmin.x, bmin.y, bmax.z));
    vec3 rdf = worldToView(vec3(bmax.x, bmin.y, bmax.z));
    vec3 luf = worldToView(vec3(bmin.x, bmax.y, bmax.z));
    vec3 ruf = worldToView(bmax);

    float d = 1000.0;

    d = min(d, distToLine(ldb.xy, ldf.xy, uv));
    d = min(d, distToLine(ldb.xy, rdb.xy, uv));
    d = min(d, distToLine(ldf.xy, rdf.xy, uv));
    d = min(d, distToLine(rdf.xy, rdb.xy, uv));

    d = min(d, distToLine(ldb.xy, lub.xy, uv));
    d = min(d, distToLine(luf.xy, ldf.xy, uv));
    d = min(d, distToLine(rdb.xy, rub.xy, uv));
    d = min(d, distToLine(ruf.xy, rdf.xy, uv));

    d = min(d, distToLine(lub.xy, luf.xy, uv));
    d = min(d, distToLine(lub.xy, rub.xy, uv));
    d = min(d, distToLine(luf.xy, ruf.xy, uv));
    d = min(d, distToLine(ruf.xy, rub.xy, uv));

    //d = min(d, length((ldb.xy * 0.5) - uv) - LINE_THICKNESS * 2.0); // Test Circle

    return d;
}

void mainImage(out vec4 o, in vec2 i)
{
    float aspect = min(iResolution.x, iResolution.y);
    vec2 uv = (i - (0.5 * iResolution.xy)) / aspect;
    float tp = 1.0 / aspect;

    vec3 col = vec3(0.0, 0.0, 0.0);

    if (SHOW_DISTANCE) col += (distToBoxLines(vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), uv));
    else col += smoothstep(LINE_THICKNESS + tp, LINE_THICKNESS - tp, distToBoxLines(vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), uv));
    o = vec4(col, 1.0);
}