#include "DryIce2Common.cginc"
// Created by David Gallardo - xjorma/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

// Pressure solver 2nd interation

// Impired by https://www.shadertoy.com/view/MdSczK by Trirop
// Since in shadertoy we don't have countless passed we need to do many pass at once.


float div(int x, int y, vec2 gl_FragCoord)
{
    return texelFetch(iChannel0, (ivec2(gl_FragCoord.xy) + ivec2(x, y))/float2(_ScreenParams.xy)).y;
}

float pre(int x, int y, vec2 gl_FragCoord)
{
    return texelFetch(iChannel0, (ivec2(gl_FragCoord.xy) + ivec2(x, y))/float2(_ScreenParams.xy)).x;
}

float getPre(vec2 gl_FragCoord)
{
    float p = 0.;
    p += 1. * pre(-10, 0, gl_FragCoord);
    p += 10. * pre(-9, -1, gl_FragCoord);
    p += 10. * pre(-9, 1, gl_FragCoord);
    p += 45. * pre(-8, -2, gl_FragCoord);
    p += 100. * pre(-8, 0, gl_FragCoord);
    p += 45. * pre(-8, 2, gl_FragCoord);
    p += 120. * pre(-7, -3, gl_FragCoord);
    p += 450. * pre(-7, -1, gl_FragCoord);
    p += 450. * pre(-7, 1, gl_FragCoord);
    p += 120. * pre(-7, 3, gl_FragCoord);
    p += 210. * pre(-6, -4, gl_FragCoord);
    p += 1200. * pre(-6, -2, gl_FragCoord);
    p += 2025. * pre(-6, 0, gl_FragCoord);
    p += 1200. * pre(-6, 2, gl_FragCoord);
    p += 210. * pre(-6, 4, gl_FragCoord);
    p += 252. * pre(-5, -5, gl_FragCoord);
    p += 2100. * pre(-5, -3, gl_FragCoord);
    p += 5400. * pre(-5, -1, gl_FragCoord);
    p += 5400. * pre(-5, 1, gl_FragCoord);
    p += 2100. * pre(-5, 3, gl_FragCoord);
    p += 252. * pre(-5, 5, gl_FragCoord);
    p += 210. * pre(-4, -6, gl_FragCoord);
    p += 2520. * pre(-4, -4, gl_FragCoord);
    p += 9450. * pre(-4, -2, gl_FragCoord);
    p += 14400. * pre(-4, 0, gl_FragCoord);
    p += 9450. * pre(-4, 2, gl_FragCoord);
    p += 2520. * pre(-4, 4, gl_FragCoord);
    p += 210. * pre(-4, 6, gl_FragCoord);
    p += 120. * pre(-3, -7, gl_FragCoord);
    p += 2100. * pre(-3, -5, gl_FragCoord);
    p += 11340. * pre(-3, -3, gl_FragCoord);
    p += 25200. * pre(-3, -1, gl_FragCoord);
    p += 25200. * pre(-3, 1, gl_FragCoord);
    p += 11340. * pre(-3, 3, gl_FragCoord);
    p += 2100. * pre(-3, 5, gl_FragCoord);
    p += 120. * pre(-3, 7, gl_FragCoord);
    p += 45. * pre(-2, -8, gl_FragCoord);
    p += 1200. * pre(-2, -6, gl_FragCoord);
    p += 9450. * pre(-2, -4, gl_FragCoord);
    p += 30240. * pre(-2, -2, gl_FragCoord);
    p += 44100. * pre(-2, 0, gl_FragCoord);
    p += 30240. * pre(-2, 2, gl_FragCoord);
    p += 9450. * pre(-2, 4, gl_FragCoord);
    p += 1200. * pre(-2, 6, gl_FragCoord);
    p += 45. * pre(-2, 8, gl_FragCoord);
    p += 10. * pre(-1, -9, gl_FragCoord);
    p += 450. * pre(-1, -7, gl_FragCoord);
    p += 5400. * pre(-1, -5, gl_FragCoord);
    p += 25200. * pre(-1, -3, gl_FragCoord);
    p += 52920. * pre(-1, -1, gl_FragCoord);
    p += 52920. * pre(-1, 1, gl_FragCoord);
    p += 25200. * pre(-1, 3, gl_FragCoord);
    p += 5400. * pre(-1, 5, gl_FragCoord);
    p += 450. * pre(-1, 7, gl_FragCoord);
    p += 10. * pre(-1, 9, gl_FragCoord);
    p += 1. * pre(0, -10, gl_FragCoord);
    p += 100. * pre(0, -8, gl_FragCoord);
    p += 2025. * pre(0, -6, gl_FragCoord);
    p += 14400. * pre(0, -4, gl_FragCoord);
    p += 44100. * pre(0, -2, gl_FragCoord);
    p += 63504. * pre(0, 0, gl_FragCoord);
    p += 44100. * pre(0, 2, gl_FragCoord);
    p += 14400. * pre(0, 4, gl_FragCoord);
    p += 2025. * pre(0, 6, gl_FragCoord);
    p += 100. * pre(0, 8, gl_FragCoord);
    p += 1. * pre(0, 10, gl_FragCoord);
    p += 10. * pre(1, -9, gl_FragCoord);
    p += 450. * pre(1, -7, gl_FragCoord);
    p += 5400. * pre(1, -5, gl_FragCoord);
    p += 25200. * pre(1, -3, gl_FragCoord);
    p += 52920. * pre(1, -1, gl_FragCoord);
    p += 52920. * pre(1, 1, gl_FragCoord);
    p += 25200. * pre(1, 3, gl_FragCoord);
    p += 5400. * pre(1, 5, gl_FragCoord);
    p += 450. * pre(1, 7, gl_FragCoord);
    p += 10. * pre(1, 9, gl_FragCoord);
    p += 45. * pre(2, -8, gl_FragCoord);
    p += 1200. * pre(2, -6, gl_FragCoord);
    p += 9450. * pre(2, -4, gl_FragCoord);
    p += 30240. * pre(2, -2, gl_FragCoord);
    p += 44100. * pre(2, 0, gl_FragCoord);
    p += 30240. * pre(2, 2, gl_FragCoord);
    p += 9450. * pre(2, 4, gl_FragCoord);
    p += 1200. * pre(2, 6, gl_FragCoord);
    p += 45. * pre(2, 8, gl_FragCoord);
    p += 120. * pre(3, -7, gl_FragCoord);
    p += 2100. * pre(3, -5, gl_FragCoord);
    p += 11340. * pre(3, -3, gl_FragCoord);
    p += 25200. * pre(3, -1, gl_FragCoord);
    p += 25200. * pre(3, 1, gl_FragCoord);
    p += 11340. * pre(3, 3, gl_FragCoord);
    p += 2100. * pre(3, 5, gl_FragCoord);
    p += 120. * pre(3, 7, gl_FragCoord);
    p += 210. * pre(4, -6, gl_FragCoord);
    p += 2520. * pre(4, -4, gl_FragCoord);
    p += 9450. * pre(4, -2, gl_FragCoord);
    p += 14400. * pre(4, 0, gl_FragCoord);
    p += 9450. * pre(4, 2, gl_FragCoord);
    p += 2520. * pre(4, 4, gl_FragCoord);
    p += 210. * pre(4, 6, gl_FragCoord);
    p += 252. * pre(5, -5, gl_FragCoord);
    p += 2100. * pre(5, -3, gl_FragCoord);
    p += 5400. * pre(5, -1, gl_FragCoord);
    p += 5400. * pre(5, 1, gl_FragCoord);
    p += 2100. * pre(5, 3, gl_FragCoord);
    p += 252. * pre(5, 5, gl_FragCoord);
    p += 210. * pre(6, -4, gl_FragCoord);
    p += 1200. * pre(6, -2, gl_FragCoord);
    p += 2025. * pre(6, 0, gl_FragCoord);
    p += 1200. * pre(6, 2, gl_FragCoord);
    p += 210. * pre(6, 4, gl_FragCoord);
    p += 120. * pre(7, -3, gl_FragCoord);
    p += 450. * pre(7, -1, gl_FragCoord);
    p += 450. * pre(7, 1, gl_FragCoord);
    p += 120. * pre(7, 3, gl_FragCoord);
    p += 45. * pre(8, -2, gl_FragCoord);
    p += 100. * pre(8, 0, gl_FragCoord);
    p += 45. * pre(8, 2, gl_FragCoord);
    p += 10. * pre(9, -1, gl_FragCoord);
    p += 10. * pre(9, 1, gl_FragCoord);
    p += 1. * pre(10, 0, gl_FragCoord);
    return  p / 1048576.;
}

void mainImage(out vec4 fragColor, in vec2 C)
{
    float p = getPre(C) - div(0, 0, C);
    fragColor = vec4(p, vec3(1,1,1));
}