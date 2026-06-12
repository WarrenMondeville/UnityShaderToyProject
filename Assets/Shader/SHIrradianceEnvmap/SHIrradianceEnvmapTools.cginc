#include "../ShaderToyTools.cginc"
/****
clear all;

% Load cubemap faces as images
cubeMapFacePosX = hdrread('cubemap/egposx.hdr');
cubeMapFacePosY = hdrread('cubemap/egposy.hdr');
cubeMapFacePosZ = hdrread('cubemap/egposz.hdr');
cubeMapFaceNegX = hdrread('cubemap/egnegx.hdr');
cubeMapFaceNegY = hdrread('cubemap/egnegy.hdr');
cubeMapFaceNegZ = hdrread('cubemap/egnegz.hdr');

cubeMapFaceWidth = size(cubeMapFacePosX,1);
cubeMapFaceHeight = size(cubeMapFacePosX,2);

% Setup a list to iterate through
cubeMap = {cubeMapFacePosX; cubeMapFacePosY; cubeMapFacePosZ;
    cubeMapFaceNegX; cubeMapFaceNegY; cubeMapFaceNegZ};

% Coordinate system
cubeMapFaceNormal   = {[1,0,0];     [0,1,0];    [0,0,1];    [-1,0,0];   [0,-1,0];   [0,0,-1]};
cubeMapFaceTangent  = {[0,0,-1];    [1,0,0];    [1,0,0];    [0,0,1];    [1,0,0];    [-1,0,0]};
cubeMapFaceBinormal = {[0,-1,0];    [0,0,1];    [0,-1,0];   [0,-1,0];   [0,0,-1];   [0,-1,0]};

% Basis functions for SH O3
y_0_p0 = 0.282095;

y_1_n1 = @(y) y .* 0.488603;
y_1_p0 = @(z) z .* 0.488603;
y_1_p1 = @(x) x .* 0.488603;

y_2_n2 = @(x,y) x.*y .* 1.092548;
y_2_n1 = @(y,z) y.*z .* 1.092548;
y_2_p0 = @(z) (3.*z.^2 - 1) .* 0.315392;
y_2_p1 = @(x,z) x.*z .* 1.092548;
y_2_p2 = @(x,y) (x.^2 - y.^2) .* 0.546274;

% Accumlators
acc = zeros(9,3);
accWeight = 0.0;

% Peform the projection
for faceIndex = 1:6
    cubeMapFace = cubeMap{faceIndex};
    for col = 1:cubeMapFaceWidth
        for row = 1:cubeMapFaceHeight
            u = double(col);
            v = double(row);
            u_scale = 1.0 / double(cubeMapFaceWidth);
            v_scale = 1.0 / double(cubeMapFaceHeight);
            u = 2.0 .* (u .* u_scale - 0.5);
            v = 2.0 .* (v .* v_scale - 0.5);
            cubeMapDir = cubeMapFaceNormal{faceIndex};
            cubeMapDir = cubeMapDir + cubeMapFaceTangent{faceIndex} .* u;
            cubeMapDir = cubeMapDir + cubeMapFaceBinormal{faceIndex} .* v;
            cubeMapDir = cubeMapDir ./ norm(cubeMapDir);
            cubeMapFace = cubeMap{faceIndex};
            funcEvalRGB = [cubeMapFace(row,col,1),cubeMapFace(row,col,2),cubeMapFace(row,col,3)];
            % Tone mapping (couldn't match the whitepaper values without this)
            funcEvalRGB = funcEvalRGB ./ 10;

            % Convolve with each basis function
            integrand = zeros(9,3);
            integrand(1,:) = funcEvalRGB .* y_0_p0;

            integrand(2,:) = funcEvalRGB .* y_1_n1(cubeMapDir(2));
            integrand(3,:) = funcEvalRGB .* y_1_p0(cubeMapDir(3));
            integrand(4,:) = funcEvalRGB .* y_1_p1(cubeMapDir(1));

            integrand(5,:) = funcEvalRGB .* y_2_n2(cubeMapDir(1),cubeMapDir(2));
            integrand(6,:) = funcEvalRGB .* y_2_n1(cubeMapDir(2),cubeMapDir(3));
            integrand(7,:) = funcEvalRGB .* y_2_p0(cubeMapDir(3));
            integrand(8,:) = funcEvalRGB .* y_2_p1(cubeMapDir(1),cubeMapDir(3));
            integrand(9,:) = funcEvalRGB .* y_2_p2(cubeMapDir(1),cubeMapDir(2));

            % Wouldn't mind an explanation of why this works
            % It's something to do with the differential solid angle of a texel
            factor = 1 + u^2+v^2;
            weight = 4.0/(sqrt(factor) .* factor);
            acc = acc + integrand .* weight;
            accWeight = accWeight + weight;
        end
    end
end

numSamples = 6 * cubeMapFaceWidth * cubeMapFaceHeight;
acc = 4.0 * pi * acc / accWeight

% Print out glsl shader code for coefficients
s1 = sprintf('vec3 l_0_p0 = vec3(%f,%f,%f);',acc(1,1),acc(1,2),acc(1,3));

s2 = sprintf('vec3 l_1_n1 = vec3(%f,%f,%f);',acc(2,1),acc(2,2),acc(2,3));
s3 = sprintf('vec3 l_1_p0 = vec3(%f,%f,%f);',acc(3,1),acc(3,2),acc(3,3));
s4 = sprintf('vec3 l_1_p1 = vec3(%f,%f,%f);',acc(4,1),acc(4,2),acc(4,3));

s5 = sprintf('vec3 l_2_n2 = vec3(%f,%f,%f);',acc(5,1),acc(5,2),acc(5,3));
s6 = sprintf('vec3 l_2_n1 = vec3(%f,%f,%f);',acc(6,1),acc(6,2),acc(6,3));
s7 = sprintf('vec3 l_2_p0 = vec3(%f,%f,%f);',acc(7,1),acc(7,2),acc(7,3));
s8 = sprintf('vec3 l_2_p1 = vec3(%f,%f,%f);',acc(8,1),acc(8,2),acc(8,3));
s9 = sprintf('vec3 l_2_p2 = vec3(%f,%f,%f);',acc(9,1),acc(9,2),acc(9,3));

sprintf('%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n',s1,s2,s3,s4,s5,s6,s7,s8,s9)
***/

float Time;

#define PI 3.1415926
#define INV_PI 1.0 / PI
#define PI_2 PI * 2.0

#define MARCH_EPS 0.065
#define GRAD_EPS 0.005

struct sdv
{
    float d;
    int idx;
};

struct rayHit
{
     vec3 p;
     int idx;
};

sdv combine(sdv a, sdv b)
{
    if (a.d < b.d)
    {
        return a;
    }

    return b;
}

#define IDX_ROOM 
#define IDX_ROOM_BOTTOM 2
#define IDX_SPHERE 3

sdv scene( vec3 p)
{
    sdv sphere;
    sphere.idx = IDX_SPHERE;

    vec3 c = vec3(0.0, 0.0, 0.0);
    float r = 24.0 + 0.5 * (sin(0.05 * p.x * p.y + iTime * 5.0));
    sphere.d = length(p - c) - r;

    return sphere;
}

 vec3 sceneGrad( vec3 p)
{
    const  float h = GRAD_EPS;
     vec3 g;
    g.x = scene(p + vec3(h, 0.0, 0.0)).d - scene(p - vec3(h, 0.0, 0.0)).d;
    g.y = scene(p + vec3(0.0, h, 0.0)).d - scene(p - vec3(0.0, h, 0.0)).d;
    g.z = scene(p + vec3(0.0, 0.0, h)).d - scene(p - vec3(0.0, 0.0, h)).d;
    return g / (2.0 * h);
}

rayHit rayQuery( vec3 start,  vec3 dir)
{
     float d = 0.0;
    const  float eps = MARCH_EPS;
    const int numIter = 76;

    for (int i = 0; i < numIter; ++i)
    {
         vec3 p = start + dir * d;
        sdv v = scene(p);
        if (v.d < eps)
        {
            rayHit ret;
            ret.idx = v.idx;
            ret.p = p;
            return ret;
        }

        d += v.d;
    }

    rayHit ret;
    ret.idx = -1;
    ret.p = 0.0;
    return ret;
}

 vec3 sceneEmittance( int idx)
{
    return 0.0;
}

 float computeAO( vec3 p,  vec3 normal)
{
     float ao = 0.0;
     vec3 k = p;
    const int numSamps = 20;
    const  float h = 1.0 / float(numSamps);
    const  float d = 0.15;

    for (int i = 0; i < numSamps; ++i)
    {
        ao += h * exp(scene(k).d);
        k += normal * d;
    }
    return clamp(ao * 0.125, 0.0, 1.0);
}

 vec3 computeIrradiance( vec3 n)
{
    // Coefficients for SH 03
    vec3 l_0_p0 = vec3(0.379727, 0.427857, 0.452654);
    vec3 l_1_n1 = vec3(0.288207, 0.358230, 0.414330);
    vec3 l_1_p0 = vec3(0.039812, 0.031627, 0.012003);
    vec3 l_1_p1 = vec3(-0.103013, -0.102729, -0.087898);
    vec3 l_2_n2 = vec3(-0.060510, -0.053534, -0.037656);
    vec3 l_2_n1 = vec3(0.008683, -0.013685, -0.045723);
    vec3 l_2_p0 = vec3(-0.092757, -0.124872, -0.152495);
    vec3 l_2_p1 = vec3(-0.059096, -0.052316, -0.038539);
    vec3 l_2_p2 = vec3(0.022220, -0.002188, -0.042826);

     vec3 irr = 0.0;

    float c1 = 0.429043;
    float c2 = 0.511664;
    float c3 = 0.743125;
    float c4 = 0.886227;
    float c5 = 0.247708;

    irr += c1 * l_2_p2 * (n.x * n.x - n.y * n.y);
    irr += c3 * l_2_p0 * (n.z * n.z);
    irr += c4 * l_0_p0;
    irr -= c5 * l_2_p0;
    irr += 2.0 * c1 * (l_2_n2 * n.x * n.y + l_2_p1 * n.x * n.z + l_2_n1 * n.y * n.z);
    irr += 2.0 * c2 * (l_1_p1 * n.x + l_1_n1 * n.y + l_1_p0 * n.z);

    return vec3(irr);
}

 vec3 computeRadiance( vec3 camPos,  vec3 camDir)
{
    rayHit q = rayQuery(camPos, camDir);
    if (q.idx >= 0)
    {
         vec3 normal = normalize(sceneGrad(q.p));
         vec3 ambient = 0.0;

         vec3 radiance = ambient;
        radiance += sceneEmittance(q.idx) +
            computeIrradiance(normal);

        return radiance;
    }

    return texture(iChannel0, camDir).rgb;
}

 mat4 lookAtInv( vec3 eyePos,  vec3 targetPos,  vec3 upVector)
{
     vec3 forward = normalize(targetPos - eyePos);
     vec3 right = normalize(cross(forward, upVector));
    upVector = normalize(cross(right, forward));

     mat4 r;
    r[0] = vec4(right, 0.0);
    r[1] = vec4(upVector, 0.0);
    r[2] = vec4(-forward, 0.0);
    r[3] = vec4(eyePos, 1.0);
    return r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    Time = iTime;

     vec2 uv = fragCoord.xy / vec2(iResolution.x, iResolution.y);

    float r = 120.0;
    float s = 0.5;
     mat4 m = lookAtInv(vec3(r * cos(Time * s), sin(Time * s) * 50.0, r * sin(Time * s)), vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
     float sw = 0.0;

    const  float aspect = 2.0;
     vec3 camPos = vec3((uv.x - 0.5) * aspect, uv.y - 0.5, 0.0);
     vec3 camDir = normalize(vec3(aspect * (uv.x - 0.5), uv.y - 0.5, -1.5 - sw));

    camPos = mul(vec4(camPos, 1.0), m).xyz;
    camDir = mul(vec4(camDir, 0.0), m).xyz;

     vec3 radiance = 0.0;
    radiance += computeRadiance(camPos, camDir);

    fragColor = vec4(pow(vec3(radiance), 1.0 / 2.2), 0.0);
}
