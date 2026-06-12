#include "../ShaderToyTools.cginc"
// All the distance functions from:http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// raymarching based from https://www.shadertoy.com/view/wdGGz3
#define PI 3.141592653589793
#define USE_MOUSE 0
#define MAX_STEPS 126
#define MAX_DIST 30.
#define SURF_DIST .002
#define framethickness 0.1
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define matRotateX(rad) mat3(1,0,0,0,cos(rad),-sin(rad),0,sin(rad),cos(rad))
#define matRotateY(rad) mat3(cos(rad),0,-sin(rad),0,1,0,sin(rad),0,cos(rad))
#define matRotateZ(rad) mat3(cos(rad),-sin(rad),0,sin(rad),cos(rad),0,0,0,1)

vec4 combine(vec4 val1, vec4 val2) {
    return (val1.w < val2.w) ? val1 : val2;
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p) - s;
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

float sdCappedCylinder(vec3 p, float h, float r)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

// https://www.shadertoy.com/view/wdGXzK
// http://mercury.sexy/hg_sdf/
vec2 pModPolar(inout vec2 p, float repetitions, float fix) {
    float angle = 2.0 * PI / repetitions;
    float a = atan(p.y, p.x) + angle / 2.;
    float r = length(p);
    float c = floor(a / angle);
    a = mod(a, angle) - angle / 2. * fix;
    p = vec2(cos(a), sin(a)) * r;

    return p;
}

float frameDist1(vec3 p) {
    float size = 1.5;
    float thickness = framethickness;
    vec4 a1 = vec4(-0.6, size, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(0.0, -size, 0.0, 1.0); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 2.0, 0.0, 0.8); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.8); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist1_2(vec3 p) {
    float size = 3.0;
    float thickness = framethickness;
    vec4 a1 = vec4(-1.2, size, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(0.0, -size, 0.0, 1.0); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 2.0, 0.0, 0.8); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.8); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist2(vec3 p) {
    float size = 1.5;
    float thickness = framethickness;
    vec4 a1 = vec4(-1.0, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(1.0, -size - 1.0, 0.0, 0.8); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 1.0); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 1.0); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist3(vec3 p) {
    float size = 1.5;
    float thickness = framethickness;
    vec4 a1 = vec4(1.5, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(-1.5, -size - 1.0, 0.0, 1.0); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.7); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.7); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist4(vec3 p) {
    float size = 1.5;
    float thickness = framethickness;
    vec4 a1 = vec4(0.0, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(0.0, -size - 1.0, 0.0, 1.0); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.2); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.2); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist5(vec3 p) {
    float size = 1.5;
    float thickness = framethickness;
    vec4 a1 = vec4(-3.2, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(3.2, -size - 1.0, 0.0, 1.2); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.44); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.44); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist6(vec3 p) {
    float size = 1.5;
    float thickness = framethickness * 0.5;
    vec4 a1 = vec4(-0.5, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(0.5, -size - 1.0, 0.0, 0.5); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 1.2); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 1.2); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist7(vec3 p) {
    float size = 1.5;
    float thickness = framethickness * 0.5;
    vec4 a1 = vec4(1.8, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(-1.8, -size - 1.0, 0.0, 0.5); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.4); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.4); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist8(vec3 p) {
    float size = 1.5;
    float thickness = framethickness * 0.5;
    vec4 a1 = vec4(-1.8, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(1.8, -size - 1.0, 0.0, 0.5); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.82); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.82); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameDist9(vec3 p) {
    float size = 1.5;
    float thickness = framethickness * 2.0;
    vec4 a1 = vec4(1.8, size + 1.0, 0.0, 0.0); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(-1.8, -size - 1.0, 0.0, 0.5); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.2); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.2); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float spokeDist(vec3 p) {
    float size = 1.5;
    float thickness = framethickness * 0.2;
    vec4 a1 = vec4(0.0, size + 1.0, 0.0, 0.8); // btm
    float p1 = dot(p, a1.xyz) + a1.w;

    vec4 a2 = vec4(0.0, -size - 1.0, 0.0, 0.8); // top
    float p2 = dot(p, a2.xyz) + a2.w;

    vec4 a3 = vec4(size, 0.0, 0.0, 0.01); // right
    float p3 = dot(p, a3.xyz) + a3.w;

    vec4 a4 = vec4(-size, 0.0, 0.0, 0.01); // left
    float p4 = dot(p, a4.xyz) + a4.w;

    vec4 a5 = vec4(0.0, 0.0, -size, thickness); // foward
    float p5 = dot(p, a5.xyz) + a5.w;

    vec4 a6 = vec4(0.0, 0.0, size, thickness); // back
    float p6 = dot(p, a6.xyz) + a6.w;

    float d = max(-p1, max(-p2, max(-p3, max(-p4, max(-p5, -p6)))));
    return d;
}

float frameFrontDist(vec3 p) {
    float f1 = frameDist1(p - vec3(0.0, 0.1, 0.0));
    float f2 = frameDist2(p - vec3(-1., -0.3, 0.0));
    float f3 = frameDist3(p - vec3(-1.1, 0.43, 0.0));
    float f4 = frameDist4(p - vec3(-1.25, 0.3, 0.0));
    float f5 = frameDist5(p - vec3(-1.37, -0.2, 0.0));

    float f6 = sdCappedCylinder(p - vec3(0.6, 0.54, 0.0), 0.08, 0.3);
    float f7 = sdCappedCylinder(p - vec3(-1.65, 1.0, 0.0), 0.08, 0.4);

    p.z = abs(p.z);
    p.z -= 0.05;
    float f8 = frameDist1_2(p - vec3(0.1, 0.28, 0.0));

    float d = min(f1, min(f2, min(f3, min(f4, min(f5, min(f6, f7))))));
    d = max(-f8, d);
    return d * 0.6;
}

float frameBackDist(vec3 p) {
    vec3 prevP = p;
    p.z = abs(p.z);
    p = mul(p, matRotateY(radians(5.0)));
    p.z -= 0.2;
    float f1 = frameDist6(p - vec3(0.25, -0.9, 0.0));
    float f2 = frameDist7(p - vec3(0.8, -0.4, 0.0));
    float f3 = frameDist8(p - vec3(-0.02, -0.6, 0.0));
    p = prevP;
    float f4 = frameDist9(p - vec3(0.8, -0.4, 0.0));

    vec3 p2 = p - vec3(-0.4, -0.8, 0.0);
    p2 = mul(p2, matRotateX(radians(90.0)));
    float f5 = sdCappedCylinder(p2, 0.07, 0.2);

    float d = min(f1, min(f2, min(f3, min(f4, f5))));
    return d * 0.6;
}

float rearSuspensionDist(vec3 p) {
    vec3 prevP = p;
    p.y = mod(p.y, 0.1) - 0.05;
    vec3 fp1 = p;
    float f1 = sdTorus(fp1, vec2(0.07, 0.03));
    p = prevP;
    fp1 = p;
    float mask = sdBox(fp1, vec3(0.1, 0.22, 0.1));
    float d3 = max(mask, f1);
    return d3 * 0.6;
}

vec4 frontSuspension(vec3 p) {
    vec3 prevP = p;
    p.x -= 1.1;
    p.y -= 1.2;
    p.z = abs(p.z);
    p.z -= 0.19;
    vec3 sp1 = p - vec3(0.0, 0.0, 0.0);
    float s1 = sdCappedCylinder(sp1, 0.08, 0.5);
    float d = s1;
    vec4 res = vec4(vec3(0.7, 0.0, 0.0), d * 0.6);

    vec3 sp2 = p - vec3(0.0, 0.9, 0.0);
    float s2 = sdCappedCylinder(sp2, 0.05, 0.53);
    d = s2;
    vec4 res2 = vec4(vec3(0.9, 0.9, 0.6), d * 0.6);

    p = prevP;
    vec3 sp3 = p - vec3(1.1, 0.8, 0.0);
    sp3 = mul(sp3, matRotateX(radians(90.0)));
    float s3 = sdCappedCylinder(sp3, 0.07, 0.12);
    d = s3;
    vec4 res3 = vec4(vec3(0.8, 0.8, 0.8), d * 0.3);

    return combine(res, combine(res2, res3));
}

vec4 stemandhandle(vec3 p) {
    vec3 prevP = p;
    vec3 sp1 = p - vec3(0.31, 2.8, 0.0);
    float s1 = sdBox(sp1, vec3(0.16, 0.08, 0.12));
    float d = s1;
    vec4 res = vec4(vec3(0.8, 0.8, 0.8), d * 0.6);

    vec3 sp2 = p - vec3(0.37, 2.8, 0.0);

    p.z = abs(p.z);
    p.z -= 0.4;
    vec3 sp3 = p - vec3(0.28, 2.9, 0.0);
    sp2 = mul(sp2, matRotateX(radians(90.0)));
    sp3 = mul(mul(sp3, matRotateX(radians(-50.0))), matRotateZ(radians(-30.0)));
    float s2 = sdCappedCylinder(sp2, 0.04, 0.3);
    float s3 = sdCappedCylinder(sp3, 0.04, 0.2);
    d = min(s2, s3);
    vec4 res2 = vec4(vec3(0.3, 0.3, 0.3), d * 0.6);

    return combine(res, res2);
}

vec4 tyre(vec3 p) {
    p.x = abs(p.x);
    p.x -= 0.95;
    vec3 prevP = p;
    p -= vec3(0.95, 1.1, 0.0);
    p.yx = pModPolar(p.yx, 20.0, 1.0);
    p.y -= 0.4;

    vec3 tp1 = p - vec3(0.0, 0.0, 0.0);
    float t1 = spokeDist(tp1);
    p = prevP;

    vec3 tp2 = p - vec3(0.95, 1.1, 0.0);
    tp2 = mul(tp2, matRotateX(radians(90.0)));
    float t2 = sdTorus(tp2, vec2(0.75, 0.03));
    float d = min(t1, t2);
    vec4 res = vec4(vec3(0.6, 0.6, 0.6), d * 0.6);

    vec3 tp3 = p - vec3(0.95, 1.1, 0.0);
    tp3 = mul(tp3, matRotateX(radians(90.0)));
    float t3 = sdTorus(tp3, vec2(0.8, 0.05));
    vec4 res2 = vec4(vec3(0.2, 0.2, 0.2), t3 * 0.3);

    return combine(res, res2);
}

vec4 saddles(vec3 p) {
    vec3 prevP = p;
    vec3 sp1 = p - vec3(-1.85, 2.9, 0.0);

    float sc = mix(0.1, 3.0, smoothstep(-1.0, 1.0, sp1.x));
    sp1.yz *= sc;
    sp1.y *= 3.0;
    sp1.z *= 1.2;
    float s1 = length(sp1) - 0.3;
    float d = s1;
    vec4 res = vec4(vec3(0.3, 0.3, 0.3), d * 0.3);

    vec3 sp2 = p - vec3(-1.8, 2.7, 0.0);
    sp2 = mul(sp2, matRotateZ(radians(-15.0)));
    float s2 = sdCappedCylinder(sp2, 0.04, 0.2);

    d = s2;
    vec4 res2 = vec4(vec3(0.8, 0.8, 0.8), d * 0.3);

    return combine(res, res2);
}

vec4 intenseM1(vec3 p) {
    vec3 front = p - vec3(1.5, 1.0, 0.0);
    mat3 frot = matRotateZ(radians(-15.0));
    front = mul(front, frot);
    float d = frameFrontDist(front);
    vec4 res = vec4(vec3(0.8, 0.0, 0.0), d * 0.5);

    vec3 back = p - vec3(-1.0, 1.0, 0.0);
    d = frameBackDist(back);
    vec4 res2 = vec4(vec3(0.8, 0.8, 0.8), d * 0.5);

    vec3 sus = p - vec3(-0.12, 0.9, 0.0);
    sus = mul(sus, matRotateZ(radians(50.0)));
    d = rearSuspensionDist(sus);
    vec4 res3 = vec4(vec3(0.8, 0.8, 0.0), d * 0.5);

    vec3 fsus = p - vec3(1.55, -0.87, 0.0);
    fsus = mul(fsus, frot);
    vec4 res4 = frontSuspension(fsus);

    vec3 stem = p - vec3(2.35, -0.75, 0.0);
    stem = mul(stem, frot);
    vec4 res5 = stemandhandle(stem);

    vec3 tyreP = p - vec3(0.5, -0.9, 0.0);
    vec4 res6 = tyre(tyreP);

    vec3 saddleP = p - vec3(1.3, -0.6, 0.0);
    vec4 res7 = saddles(saddleP);

    return combine(res, combine(res2, combine(res3, combine(res4, combine(res5, combine(res6, res7))))));
}

vec4 GetDist(vec3 p) {
    vec4 res = intenseM1(p - vec3(-0.4, 0.0, 0.0));
    return res;
}

vec4 RayMarch(vec3 ro, vec3 rd) {
    vec4 dO = vec4(0.0, 0.0, 0.0, 1.0);

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO.w;
        vec4 dS = GetDist(p);
        dO.w += dS.w;
        dO.xyz = dS.xyz;
        if (dO.w > MAX_DIST || dS.w < SURF_DIST) break;
    }

    return dO;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p).w;
    vec2 e = vec2(.001, 0);

    vec3 n = d - vec3(
        GetDist(p - e.xyy).w,
        GetDist(p - e.yxy).w,
        GetDist(p - e.yyx).w);

    return normalize(n);
}

vec2 GetLight(vec3 p) {
    vec3 lightPos = vec3(2, 9, 3);
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p);

    float dif = clamp(dot(n, l) * .5 + .5, 0., 1.);
    float d = RayMarch(p + n * SURF_DIST * 2., l).w;

    float lambert = max(.0, dot(n, l)) * 0.1;

    return vec2((lambert + dif), 1.0);
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p),
        r = normalize(cross(vec3(0, 1, 0), f)),
        u = cross(f, r),
        c = p + f * z,
        i = c + uv.x * r + uv.y * u,
        d = normalize(i - p);
    return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy / iResolution.xy;
    float t = mod(iTime, 8000.0);

    vec3 col = vec3(0, 0, 0);

    vec3 ro = vec3(0, 4, -4.5);
#if USE_MOUSE == 1
    ro.yz = mul(ro.yz, Rot(-m.y * 3.14 + 1.));
    ro.xz = mul(ro.xz, Rot(-m.x * 6.2831));
#else
    ro.yz = mul(ro.yz, Rot(radians(-30.0)));
    ro.xz = mul(ro.xz, Rot(t * .3 + 1.0));
#endif

    vec3 rd = R(uv, ro, vec3(0, 1, 0), 1.);

    vec4 d = RayMarch(ro, rd);

    if (d.w < MAX_DIST) {
        vec3 p = ro + rd * d.w;

        vec2 dif = GetLight(p);
        col = vec3(dif.xxx) * d.xyz;
        col *= dif.y;

    }
    else {
        // background
        col = .84 * max(mix(vec3(1.2, 1.2, 1.1) + (.1 - length(uv.xy) / 3.), vec3(1, 1, 1), .1), 0.);
    }

    fragColor = vec4(col, 1.0);
}