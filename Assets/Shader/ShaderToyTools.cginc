#define vec4 float4
#define vec3 float3
#define vec2 float2
#define ivec2 int2
#define ivec3 int3
#define uvec2 uint2
#define mat2 float2x2
#define mat2x2 float2x2
#define mat3 float3x3
#define mat4 float4x4
#define fract frac
#define mix lerp

#define dFdx ddx
#define dFdy ddy

//#define smoothstep lerp
#define iTime _Time.y
float iFrame;
//#define mod fmod
#define atan atan2
#define iResolution _ScreenParams
#define texture tex2D
#define textureLod tex2D
#define texelFetch tex2D
sampler2D iChannel0;
sampler2D iChannel1;
sampler2D iChannel2;
sampler2D iChannel3;
float4 iMouse;
float iTimeDelta;

float mod(float x,float y)
{
    return frac(x/y) * y;
}

float2 mod(float2 x, float2 y)
{
    return frac(x / y) * y;
}

float3 mod(float3 x, float3 y)
{
    return frac(x / y) * y;
}

float4 mod(float4 x, float4 y)
{
    return frac(x / y) * y;
}

float smoothstep(float a, float b, float x)
{
    float t = saturate((x - a) / (b - a));
    return t * t * (3.0 - (2.0 * t));
}

float2 smoothstep(float2 a, float2 b, float2 x)
{
    float2 t = saturate((x - a) / (b - a));
    return t * t * (3.0 - (2.0 * t));
}

float3 smoothstep(float3 a, float3 b, float3 x)
{
    float3 t = saturate((x - a) / (b - a));
    return t * t * (3.0 - (2.0 * t));
}

float inversesqrt(float x)
{
    return 1.0 / sqrt(x);
}

float2 inversesqrt(float2 x)
{
    return 1.0 / sqrt(x);
}

float3 inversesqrt(float3 x)
{
    return 1.0 / sqrt(x);
}

float4 inversesqrt(float4 x)
{
    return 1.0 / sqrt(x);
}