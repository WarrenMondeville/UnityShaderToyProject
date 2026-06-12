#include "DryIce2Common.cginc"
// Created by David Gallardo - xjorma/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

// Divergence

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    ivec2 icoord = ivec2(fragCoord);
    float vel_x_left = texelFetch(iChannel0, (icoord + ivec2(-1, 0)) / float2(_ScreenParams.xy)).x;
    float vel_x_right = texelFetch(iChannel0, (icoord + ivec2(1, 0)) / float2(_ScreenParams.xy)).x;
    float vel_y_bottom = texelFetch(iChannel0, (icoord + ivec2(0, -1)) / float2(_ScreenParams.xy)).y;
    float vel_y_top = texelFetch(iChannel0, (icoord + ivec2(0, 1)) / float2(_ScreenParams.xy)).y;
    float divergence = (vel_x_right - vel_x_left + vel_y_top - vel_y_bottom) * 0.5;
    fragColor = vec4(divergence, vec3(1,1,1));
}