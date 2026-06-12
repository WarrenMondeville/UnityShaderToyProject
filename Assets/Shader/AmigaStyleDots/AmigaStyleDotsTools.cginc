#include "../ShaderToyTools.cginc"
#define PI 3.1415926536
#define NUM_DOTS_IN_RING 64
#define MAGIC_CONST ((2.0*PI)/float(NUM_DOTS_IN_RING))
#define DOT_SIZE 0.1
#define NUM_RINGS 64
#define RING_SCALE 0.05
#define EPSILON 0.00001
#define BASE_SIZE 0.001
#define SPEED 8.0

float circ(vec2 uv, vec2 cPos, float cSize)
{
    return 1.0 - smoothstep(0.0, cSize, length(uv - cPos)) / cSize;
}

float ring(vec2 uv, vec2 rPos, float rSize)
{
    //center ourselves about the ring
    vec2 myPos = uv - rPos;

    //some polar fun
    float angle = atan(myPos.y, myPos.x);

    float c = MAGIC_CONST;
    float nearestAngle = c * round(angle / c);
    //return vec3(nearestAngle/(2.0*PI));
    vec2 nearestDotPos;
    nearestDotPos.x = cos(nearestAngle) * rSize;
    nearestDotPos.y = sin(nearestAngle) * rSize;

    float dotSize = DOT_SIZE;
    return circ(myPos, nearestDotPos, dotSize);
}


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates
    vec2 uv = fragCoord / iResolution.xy;
    uv -= 0.5;
    uv *= 2.0;
    uv.x *= iResolution.x / iResolution.y;

    float col;

    for (int i = NUM_RINGS + 1; i > 0; i--) {
        float fi = float(i);
        float scaledTime = SPEED * iTime;
        float scale = mod(scaledTime, 1.0);
        float size = (fi + scale) * RING_SCALE + BASE_SIZE;
        float ringNum = scale + fi;
        float move = (iTime + ringNum / 16.0);
        col = ring(uv, vec2(cos(move * 0.7) * 1.5, sin(cos(move) * 2.5) * 0.5), size);
        //float col = ring(uv, vec2(0.0), size);
        if (col > EPSILON) {
            float colRange = mod((scaledTime - fi), 8.0);
            col /= 1.0 + float(colRange < 4.0);
            break;
        }
    }


    // Output to screen
    fragColor = vec4(vec3(col, col, col), 1.0);
}