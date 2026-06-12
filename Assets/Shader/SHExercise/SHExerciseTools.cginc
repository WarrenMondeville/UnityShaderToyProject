#include "../ShaderToyTools.cginc"
// Created by Raul Aguaviva - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// The point of this shader is to show the sort of artifacts that SH introduce.

// The left side of the screen shows the visibility computed stochastically, 
// The right side encodes that visibility in spherical harmonics and immediately it decodes it. 
//
// Spherical harmonics are using extensively in quantum mechanics to study the hydrogen atom. 
// did you ever wonder why the SHs use the letters 'l' and 'm'? That is because 'l' is the angular 
// momentum and 'm' is the magnetic number. All the SHs that have the same 'l' have the same angular 
// momentum (represented often with the letter 'L')
//
// This sample uses a fair amount of code from these samples (Thanks to IQ): 
// 	- https://www.shadertoy.com/view/4djSDy
// 	- https://www.shadertoy.com/view/lsfXWH
//
// Thanks to Matt Pharr for his excellent PBR book and in special for the SH chapter.

#define SAMPLECOUNT 150

// Constants, see here: http://en.wikipedia.org/wiki/Table_of_spherical_harmonics
#define k01 0.2820947918 // sqrt(  1/PI)/2
#define k02 0.4886025119 // sqrt(  3/PI)/2
#define k03 1.0925484306 // sqrt( 15/PI)/2
#define k04 0.3153915652 // sqrt(  5/PI)/4
#define k05 0.5462742153 // sqrt( 15/PI)/4
#define k06 0.5900435860 // sqrt( 70/PI)/8
#define k07 2.8906114210 // sqrt(105/PI)/2
#define k08 0.4570214810 // sqrt( 42/PI)/8
#define k09 0.3731763300 // sqrt(  7/PI)/4
#define k10 1.4453057110 // sqrt(105/PI)/4

// Y_l_m(s), where l is the band and m the range in [-l..l] 
float SphericalHarmonic(in int l, in int m, in vec3 s)
{
    vec3 n = s.zxy;

    //----------------------------------------------------------
    if (l == 0)          return  k01;

    //----------------------------------------------------------
    if (l == 1 && m == -1) return -k02 * n.y;
    if (l == 1 && m == 0) return  k02 * n.z;
    if (l == 1 && m == 1) return -k02 * n.x;

    //----------------------------------------------------------
    if (l == 2 && m == -2) return  k03 * n.x * n.y;
    if (l == 2 && m == -1) return -k03 * n.y * n.z;
    if (l == 2 && m == 0) return  k04 * (3.0 * n.z * n.z - 1.0);
    if (l == 2 && m == 1) return -k03 * n.x * n.z;
    if (l == 2 && m == 2) return  k05 * (n.x * n.x - n.y * n.y);
    //----------------------------------------------------------
    if (l == 3 && m == -3) return -k06 * n.y * (3.0 * n.x * n.x - n.y * n.y);
    if (l == 3 && m == -2) return  k07 * n.z * n.y * n.x;
    if (l == 3 && m == -1) return -k08 * n.y * (5.0 * n.z * n.z - 1.0);
    if (l == 3 && m == 0) return  k09 * n.z * (5.0 * n.z * n.z - 3.0);
    if (l == 3 && m == 1) return -k08 * n.x * (5.0 * n.z * n.z - 1.0);
    if (l == 3 && m == 2) return  k10 * n.z * (n.x * n.x - n.y * n.y);
    if (l == 3 && m == 3) return -k06 * n.x * (n.x * n.x - 3.0 * n.y * n.y);
    //----------------------------------------------------------

    return 0.0;
}

struct SphericalHarmonicsCoeffs
{
    float v[9];
};

void  SphericalHarmonicsInit(out SphericalHarmonicsCoeffs coeffs)
{
    for (int i = 0; i < 9; i++)
    {
        coeffs.v[i] = 0.;
    }
}

void SphericalHarmonicsMul(float scalar, inout SphericalHarmonicsCoeffs coeffs)
{
    for (int i = 0; i < 9; i++)
    {
        coeffs.v[i] *= scalar;
    }
}



void SphericalHarmonicsProject(vec3 n, float value, inout SphericalHarmonicsCoeffs coeffs)
{
    coeffs.v[0] += SphericalHarmonic(0, 0, n) * value;

    coeffs.v[1] += SphericalHarmonic(1, -1, n) * value;
    coeffs.v[2] += SphericalHarmonic(1, 0, n) * value;
    coeffs.v[3] += SphericalHarmonic(1, 1, n) * value;

    coeffs.v[4] += SphericalHarmonic(2, -2, n) * value;
    coeffs.v[5] += SphericalHarmonic(2, -1, n) * value;
    coeffs.v[6] += SphericalHarmonic(2, 0, n) * value;
    coeffs.v[7] += SphericalHarmonic(2, 1, n) * value;
    coeffs.v[8] += SphericalHarmonic(2, 2, n) * value;

}

float SphericalHarmonicsEval(vec3 n, in SphericalHarmonicsCoeffs coeffs)
{
    float res = 0.;

    res += SphericalHarmonic(0, 0, n) * coeffs.v[0];

    res += SphericalHarmonic(1, -1, n) * coeffs.v[1];
    res += SphericalHarmonic(1, 0, n) * coeffs.v[2];
    res += SphericalHarmonic(1, 1, n) * coeffs.v[3];

    res += SphericalHarmonic(2, -2, n) * coeffs.v[4];
    res += SphericalHarmonic(2, -1, n) * coeffs.v[5];
    res += SphericalHarmonic(2, 0, n) * coeffs.v[6];
    res += SphericalHarmonic(2, 1, n) * coeffs.v[7];
    res += SphericalHarmonic(2, 2, n) * coeffs.v[8];

    return res;
}

//=====================================================

// Sphere intersection
float sphIntersect(in vec3 ro, in vec3 rd, in vec4 sph)
{
    vec3 oc = ro - sph.xyz;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - sph.w * sph.w;
    float h = b * b - c;
    if (h < 0.0) return -1.0;
    return -b - sqrt(h);
}

float iPlane(in vec3 ro, in vec3 rd)
{
    return (-1.0 - ro.y) / rd.y;
}

float Scene(in vec3 pos, in vec3 dir, out vec3 normal)
{
    float tmin = 1e3;

    pos += dir * 0.0001; //just to avoid self intersections

    vec4 sph = vec4(cos(.5 * iTime + vec3(2.0, 1.0, 1.0) + 0.0) * vec3(0., 1.2, 0.0), 1.0);
    float t2 = sphIntersect(pos, dir, sph);
    if (t2 > 0.0 && t2 < tmin)
    {
        tmin = t2;
        vec3 tpos = pos + tmin * dir;
        normal = normalize(tpos - sph.xyz);
    }

    t2 = iPlane(pos, dir);
    if (t2 > 0.0 && t2 < tmin)
    {
        tmin = t2;
        normal = vec3(0.0, 1.0, 0.0);
    }


    return tmin;
}

float SceneViz(in vec3 pos, in vec3 dir)
{
    vec3 normal;
    float res = Scene(pos, dir, normal);
    return res != 1e3 ? 1. : 0.;//step(0.0,res);    
}


//=====================================================

vec2 hash2(float n) { return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453123, 22578.1459123)); }

float ComputeViz(in vec3 pos, in vec3 dir)
{
    vec3  ru = normalize(cross(dir, vec3(0.0, 1.0, 1.0)));
    vec3  rv = normalize(cross(ru, dir));

    float occ = 0.0;
    for (int i = 0; i < SAMPLECOUNT; i++)
    {
        vec2  aa = hash2(float(i) * 203.1);
        float ra = sqrt(aa.y);
        float rx = ra * cos(6.2831 * aa.x);
        float ry = ra * sin(6.2831 * aa.x);
        float rz = sqrt(1.0 - aa.y);
        vec3  rdir = vec3(rx * ru + ry * rv + rz * dir);

        occ += SceneViz(pos, rdir);
    }
    occ /= float(SAMPLECOUNT);

    return occ;
}

void ComputeVizSH(in vec3 pos, in vec3 dir, out SphericalHarmonicsCoeffs coeffsVis)
{
    SphericalHarmonicsInit(coeffsVis);

    vec3  ru = normalize(cross(dir, vec3(0.0, 1.0, 1.0)));
    vec3  rv = normalize(cross(ru, dir));

    for (int i = 0; i < SAMPLECOUNT; i++)
    {
        vec2  aa = hash2(float(i) * 203.1);
        float ra = sqrt(aa.y);
        float rx = ra * cos(6.2831 * aa.x);
        float ry = ra * sin(6.2831 * aa.x);
        float rz = sqrt(1.0 - aa.y);
        vec3  rdir = vec3(rx * ru + ry * rv + rz * dir);

        float occ = SceneViz(pos, rdir);
        if (occ > .0)
        {
            SphericalHarmonicsProject(rdir, 1., coeffsVis);
        }
    }

    //montecarlo stuff
    SphericalHarmonicsMul(2.0 * (2.0 * 3.1415) / float(SAMPLECOUNT), coeffsVis);
}


//note that when we are evaluating we need to sample the whole sphere
float EvalVisibilitySH(SphericalHarmonicsCoeffs coeffsVis)
{
    float occ = 0.0;
    for (int i = 0; i < SAMPLECOUNT; i++)
    {
        vec2  aa = hash2(float(i) * 203.1);
        float rz = 1. - 2. * aa.y;
        float ra = sqrt(1. - rz * rz);
        float rx = ra * cos(6.2831 * aa.x);
        float ry = ra * sin(6.2831 * aa.x);

        vec3  rdir = vec3(rx, ry, rz);

        occ += SphericalHarmonicsEval(rdir, coeffsVis);
    }
    occ /= float(SAMPLECOUNT);

    return occ;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 p = (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
    float s = (2.0 * iMouse.x - iResolution.x) / iResolution.y;
    if (iMouse.z < 0.001) s = 0.0;

    vec3 ro = vec3(0.0, 0.0, 4.0);
    vec3 rd = normalize(vec3(p, -2.0));

    vec3 col = 0.0;

    float tmin = 1e10;
    vec3 nor = vec3(0.0, 0.0, 0.0);
    float t1 = Scene(ro, rd, nor);
    if (t1 > 0.0)
    {
        tmin = t1;
        vec3 pos = ro + tmin * rd;

        float occ = 0.0;

        col = 1.0;

        if (p.x > s)
        {
            SphericalHarmonicsCoeffs vizCoeffs = (SphericalHarmonicsCoeffs)0;

            //encode visibility function into spherical harmonics            
            ComputeVizSH(pos, nor, vizCoeffs);

            //evaluate for the normal direction
            occ = EvalVisibilitySH(vizCoeffs);
        }
        else
        {
            occ = ComputeViz(pos, nor);
        }

        col *= 1.0 - occ;
    }

    col *= exp(-0.05 * tmin);

    float e = 2.0 / iResolution.y;
    col *= smoothstep(0.0, 2.0 * e, abs(p.x - s));

    //gamma, not used to make the effect more dramatic
    col = pow(col, 1.0 / 2.2);

    fragColor = vec4(col, 1.0);
}