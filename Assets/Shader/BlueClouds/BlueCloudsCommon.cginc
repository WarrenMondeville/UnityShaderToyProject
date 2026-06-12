#include "../ShaderToyTools.cginc"
//#define BLUR //uncomment this if you see artifacts
#define MARGIN //comment this to remove margins

#define TIME (iTime*0.05)
#define saturate(x) clamp(x,0.0,1.0)
#define UV (fragCoord.xy/iResolution.xy)
#define SUNCOLOR vec3(0.929,0.831,0.929)
#define SUNPOS ((iMouse.xy-iResolution.xy*0.5)/iResolution.y)

#define STEPS 32.0 //make this 16.0 if your pc cant handle it

#define radialLength 0.96
#define imageBrightness 9.0
#define flareBrightness 4.5
#define marginSize 0.08
#define M2 mat2(0.8, -0.6, 0.6, 0.8)

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453) * 2.0 - 1.0;
}