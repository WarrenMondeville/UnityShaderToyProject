#include "../ShaderToyTools.cginc"
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

#define pi acos(-1.)


#define pmod(p,a) mod(p - 0.5*(a),(a)) - 0.5*(a)

mat3 getOrthogonalBasis(vec3 direction) {
    direction = normalize(direction);
    vec3 right = normalize(cross(vec3(0, 1, 0), direction));
    vec3 up = normalize(cross(direction, right));
    return mat3(right, up, direction);
}
float cyclicNoise(vec3 p, bool turbulent, float time) {
    float noise = 0.;

    p.yz = mul(p.yz,rot(0.5));
    float amp = 1.;
    float gain = 0.9 + sin(p.z * 0.2) * 0.2;
    const float lacunarity = 1.6;
    const int octaves = 5;

    const float warp = 2.2;
    float warpTrk = 1.5;
    const float warpTrkGain = .2;

    vec3 seed = vec3(-4, -2., 0.5);
    mat3 rotMatrix = getOrthogonalBasis(seed);

    for (int i = 0; i < octaves; i++) {

        p += sin(p.zxy * warpTrk + vec3(0, -time * 2., 0) - 2. * warpTrk) * warp;
        noise += sin(dot(cos(p), sin(p.zxy + vec3(0, time * 0.3, 0)))) * amp;

        p = mul(p, rotMatrix);
        p *= lacunarity;

        warpTrk *= warpTrkGain;
        amp *= gain;
    }

    if (turbulent) {
        return 1. - abs(noise) * 0.5;

    } {
        return (noise * 0.25 + 0.5);

    }
}