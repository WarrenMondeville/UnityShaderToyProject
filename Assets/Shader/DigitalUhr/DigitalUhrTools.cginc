#include "../ShaderToyTools.cginc"
#define red vec3(1.0,0.0,0.0)
#define green vec3(0.0,1.0,0.0)
#define blue vec3(0.0,0.0,1.0)
#define yellow vec3(1.0,1.0,0.0)

float iDate[4];

const bool gradient = true; //if the lines should have rounded edges

vec4 BG(vec2 fragCoord) {
    vec4 rgi = mix(vec4(vec3(1.0, 0.0, 0.0), 1.0), vec4(vec3(0.0, 1.0, 0.0), 1.0), fragCoord.x / iResolution.x);
    vec4 byi = mix(vec4(vec3(0.0, 0.0, 1.0), 1.0), vec4(vec3(1.0, 1.0, 0.0), 1.0), fragCoord.x / iResolution.x);
    return mix(rgi, byi, fragCoord.y / iResolution.y);
}

vec4 CombineLayers(vec4 topl, vec4 bottoml) {
    return mix(bottoml, topl, topl.a);
}

float DistLinePoint(vec2 P1, vec2 P2, vec2 P0) {
    return abs((P2.y - P1.y) * P0.x - (P2.x - P1.x) * P0.y + P2.x * P1.y - P1.x * P2.y) / sqrt(pow((P2.y - P1.y), 2.0) + pow((P2.x - P1.x), 2.0));
}

float Line(vec2 L1, vec2 L2, float width, vec2 fragCoord) {
    float outval = 1.0;
    float lengthL = distance(L1, L2);

    float deltax = L1.x - L2.x;
    float deltay = L1.y - L2.y;

    vec2 borderPoint1 = vec2(L1.x + deltay, L1.y - deltax);
    vec2 borderPoint2 = vec2(L2.x + deltay, L2.y - deltax);

    if (max(DistLinePoint(L1, borderPoint1, fragCoord), DistLinePoint(L2, borderPoint2, fragCoord)) > lengthL) {
        outval = min(distance(L1, fragCoord), distance(L2, fragCoord)) / width;
    }
    else {
        outval = DistLinePoint(L1, L2, fragCoord) / width;
    }
    if (gradient) {
        return min(1.0, 1.0 - outval);
    }
    else {
        if (1.0 - outval >= 0.5) {
            return 1.0;
        }
        else {
            return 0.0;
        }
    }
}
float Dot(float r, float width, vec2 fragCoord) {
    if (gradient) {
        return min(1.0, 1.0 - (distance(iResolution.xy / 2.0, fragCoord) - r) / width);
    }
    else {
        if (1.0 - (distance(iResolution.xy / 2.0, fragCoord) - r) / width >= 0.5) {
            return 1.0;
        }
        else {
            return 0.0;
        }
    }
}
float Circle(float r, float width, vec2 fragCoord) {
    if (gradient) {
        return min(1.0, 1.0 - abs(distance(iResolution.xy / 2.0, fragCoord) - r) / width);
    }
    else {
        if (1.0 - abs(distance(iResolution.xy / 2.0, fragCoord) - r) / width >= 0.5) {
            return 1.0;
        }
        else {
            return 0.0;
        }
    }

}
float CircleLine(float r, float angle, float width, vec2 fragCoord) {
    float deltax = sin(radians(angle)) * r;
    float deltay = cos(radians(angle)) * r;
    vec2 P2 = vec2((iResolution.xy / 2.0).x + deltax, (iResolution.xy / 2.0).y + deltay);
    return Line(iResolution.xy / 2.0, P2, width, fragCoord);
}
float CircleLineSegment(float r1, float r2, float angle, float width, vec2 fragCoord) {
    float deltax1 = sin(radians(angle)) * r1;
    float deltay1 = cos(radians(angle)) * r1;
    vec2 P1 = vec2((iResolution.xy / 2.0).x + deltax1, (iResolution.xy / 2.0).y + deltay1);

    float deltax2 = sin(radians(angle)) * r2;
    float deltay2 = cos(radians(angle)) * r2;
    vec2 P2 = vec2((iResolution.xy / 2.0).x + deltax2, (iResolution.xy / 2.0).y + deltay2);

    return Line(P1, P2, width, fragCoord);
}

float getHours() {
    return floor(iDate[3] / 3600.0);
}
float getMinutes() {
    return floor((iDate[3] - getHours() * 3600.0) / 60.0);
}
float getSeconds() {
    return floor(iDate[3] - getHours() * 3600.0 - getMinutes() * 60.0);
}

float HourHand(vec2 fragCoord) {
    return CircleLine(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) / 2.0, mod(30.0 * getHours(), 360.0), min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 4.0 / 150.0, fragCoord);
}
float MinuteHand(vec2 fragCoord) {
    return CircleLine(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 2.0 / 3.0, getMinutes() * 6.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 4.0 / 150.0, fragCoord);
}
float SecondHand(vec2 fragCoord) {
    return CircleLine(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 22.0 / 30.0, getSeconds() * 6.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 2.0 / 150.0, fragCoord);
}

float HourMarks(vec2 fragCoord) {
    float maxVal = 0.0;
    for (int i = 0; i < 12; i++) {
        maxVal = max(maxVal, CircleLineSegment(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 13.0 / 15.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0), float(i) * 30.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 3.0 / 150.0, fragCoord));
    }
    return maxVal;
}
float MinuteMarks(vec2 fragCoord) {
    float maxVal = 0.0;
    for (int i = 0; i < 60; i++) {
        if (mod(float(i), 5.0) != 0.0) {
            maxVal = max(maxVal, CircleLineSegment(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 13.0 / 15.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 27.0 / 30.0, float(i) * 6.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 3.0 / 150.0, fragCoord));
        }
    }
    return maxVal;
}

float Dial(vec2 fragCoord) {
    float circ = Circle(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0), min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 3.0 / 150.0, fragCoord);
    float tHourMarks = HourMarks(fragCoord);
    float tMinuteMarks = MinuteMarks(fragCoord);
    float MiddleAxis = Dot(min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) / 150.0, min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0) * 4.0 / 150.0, fragCoord);
    return max(circ, max(tHourMarks, max(tMinuteMarks, MiddleAxis)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float HourH = HourHand(fragCoord);
    float MinuteH = MinuteHand(fragCoord);
    float SecondH = SecondHand(fragCoord);
    float tDial = Dial(fragCoord);

    float mask = max(tDial, max(HourH, max(MinuteH, SecondH)));

    float circle = float(distance(iResolution.xy / 2.0, fragCoord) < min(iResolution.x * 5.0 / 12.0, iResolution.y / 2.0 - 30.0));

    fragColor = CombineLayers((mask), BG(fragCoord) * (1.0 - circle) + BG(fragCoord) * 0.7 * circle);
}