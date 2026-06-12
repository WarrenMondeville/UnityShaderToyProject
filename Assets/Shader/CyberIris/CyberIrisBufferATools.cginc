#include "../ShaderToyTools.cginc"
#include"CyberIrisCommon.cginc"
#define M_PI 3.1415926535897932384626433832795

#define timeScale 0.2

#define mainColor vec3(0.478431, 0.678431, 1.)
#define secondaryColor vec3(0.55, 0.0, 0.0)

/*
* Displays the sector of a ring based on:
*
* dist		... distance to the center (/ radius)
* width		... width (along the radius)
* apos		... angular position (/ offset)
* awidth	... angular width (along the tangent)
* puv		... polar uv coordinates of the current fragment
*
* returns 1.0 if the given puv is part of the ringSector
* returns 0.0 otherwise
*/
float ringSector(float dist, float width, float apos, float awidth, vec2 puv) {

    float ring = step(abs(puv.x - dist), width / 2.0);

    float sector = min(min(
        abs(puv.y - mod(apos, 1.0)),
        abs(puv.y - mod(apos, 1.0) - 1.0)),
        abs(puv.y - mod(apos, 1.0) + 1.0));
    sector = step(sector, awidth / 2.0);

    return ring * sector;
}

/*
* Displays an array of ring sectors based on:
*
* dist		... distance to the center (/ radius)
* width		... width (along the radius)
* apos		... angular position (/ offset)
* awidth	... angular width of the sector array (along the tangent)
* segCount	... how many ring sectors should be used to create the sector array
* segWidth	... the width of the individual ring sector (along the tangent; values between 0.0 and 1.0)
* puv		... polar uv coordinates of the current fragment
*
* returns 1.0 if the given puv is part of the sector array
* returns 0.0 otherwise
*/
float ringSectors(float dist, float width, float apos, float awidth, int segCount, float segWidth, vec2 puv) {
    float ret = 0.;
    float sW = awidth / float(segCount);
    float p = apos - float(segCount) / 2.0 * sW + sW / 2.0;

    for (int i = 0; i < segCount; i++) {
        ret += ringSector(dist, width, p + sW * float(i), sW * segWidth, puv);
    }

    return ret;
}

/*
* Displays an array of ring sectors with randomized angular position based on:
*
* dist		... distance to the center (/ radius)
* width		... width (along the radius)
* apos		... angular position (/ offset)
* awidth	... the width of the individual ring segments (along the tangent)
* segCount	... how many ring sectors should randomly distributed
* seed		... seed used for the hash function
* puv		... polar uv coordinates of the current fragment
*
* returns 1.0 if the given puv is part of the randomized ring sectors
* returns 0.0 otherwise
*/
float randSectors(float dist, float width, float apos, float awidth, int segCount, float seed, vec2 puv) {
    float ret = 0.;

    for (int i = 0; i < segCount; i++) {
        float rpos = hash11((float(i) + seed) * 10032.);
        ret = max(ret, ringSector(dist, width, apos + rpos, awidth, puv));
    }

    return ret;
}

/*
* Displays a ring sector that incorporates two symmetrical slopes alongside the tangent based on:
*
* dist		... distance to the center (/ radius)
* w1		... width of the sector before the slope (along the radius)
* w2		... width of the sector after the slope (along the radius)
* apos		... angular position (/ offset)
* awidth	... angular width (along the tangent)
* t1		... threshold 1 defines the relative start of the slope (value between 0.0 and 1.0)
* t2		... threshold 2 defines the relative end of the slope (value between 0.0 and 1.0)
* innerC	... set 1.0 so that the inner half of the sector gets drawn completely; set 0.0 otherwise
* outerC	... set 1.0 so that the outer half of the sector gets drawn completely; set 0.0 otherwise
* puv		... polar uv coordinates of the current fragment
*
* returns 1.0 if the given puv is part of the slanted sector
* returns 0.0 otherwise
*/
float slantedSector(float dist, float w1, float w2, float apos, float awidth, float t1, float t2, float innerC, float outerC, vec2 puv) {

    float sector = min(min(
        abs(puv.y - mod(apos, 1.0)),
        abs(puv.y - mod(apos, 1.0) - 1.0)),
        abs(puv.y - mod(apos, 1.0) + 1.0));

    float slopeProgress = linstep(t1 * awidth / 2., t2 * awidth / 2., sector);

    float ring = step(abs(puv.x - dist), mix(w2, w1, slopeProgress));
    //float ring = step(abs(puv.x - dist), (slopeProgress * w1 + (1. - slopeProgress) * w2) / 2.0);

    // cover inner / outer half of ring
    float w = max(w1, w2);
    ring = max(ring, step(abs(puv.x - (dist + w / 2.)), w / 2.) * outerC);
    ring = max(ring, step(abs(puv.x - (dist - w / 2.)), w / 2.) * innerC);

    sector = step(abs(sector), awidth / 2.0);

    return ring * sector;
}

/*
* Displays a ring built from multiple slanted sectors based on:
*
* dist		... distance to the center (/ radius)
* w1		... width of the sectors before the slope (along the radius)
* w2		... width of the sectors after the slope (along the radius)
* apos		... angular position (/ offset)
* segCount	... how many slanted sectors should be used to create the ring
* t1		... threshold 1 defines the relative start of the slope of each sector (value between 0.0 and 1.0)
* t2		... threshold 2 defines the relative end of the slope of each sector (value between 0.0 and 1.0)
* innerC	... set 1.0 so that the inner half of the ring gets drawn completely; set 0.0 otherwise
* outerC	... set 1.0 so that the outer half of the ring gets drawn completely; set 0.0 otherwise
* puv		... polar uv coordinates of the current fragment
*
*/
float slantedRing(float dist, float w1, float w2, float apos, int segCount, float t1, float t2, float innerC, float outerC, vec2 puv) {
    float ret = 0.;

    float segWidth = 1. / float(segCount);

    for (int i = 0; i < segCount; i++) {
        ret += slantedSector(dist, w1, w2, apos + segWidth * float(i), segWidth, t1, t2, innerC, outerC, puv);
    }

    return ret;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates (from -0.5 to 0.5)
    vec2 uv = fragCoord / iResolution.xy - 0.5;
    uv *= vec2(iResolution.x / iResolution.y, 1.0);

    // polar uv (x = radius, y = angle)
    vec2 puv = vec2(length(uv), atan(uv.x, uv.y) / (M_PI * 2.0));


    float t = iTime * timeScale;

    float fill = 0.0;
    float fill2 = 0.0;

    // inner
    fill += ringSector(0.01, 0.004, t * 8., 0.4, puv);
    fill += ringSector(0.006, 0.004, -t * 4., 0.2, puv);

    // reactor
    fill += ringSector(0.05, 0.025, -t, 0.575, puv);
    fill += ringSector(0.05, 0.05, t * 0.5, 0.1, puv);
    fill += ringSectors(0.05, 0.025, -t + 0.5, 0.4, 4, 0.8, puv);
    fill += ringSector(0.05, 0.0125, 0., 1., puv);

    // train
    fill += ringSectors(0.15, 0.01, -t, 0.25, 7, 0.7, puv);

    // trail
    fill += ringSector(0.2, 0.015, t * 1.3, 0.15, puv);
    fill += ringSector(0.2, 0.015, t * 1.3 + 0.1, 0.025, puv);

    // clock
    fill += ringSectors(0.1, 0.02, t * 1.0, 1.0, 20, 0.1, puv);
    fill += ringSectors(0.1, 0.03, t * 1.0 + 0.025, 1.0, 5, 0.025, puv);

    //stripes
    fill += ringSectors(0.25, 0.005, t * 0.1, 0.3, 100, 0.5, puv);

    //shutter
    /*
    //float tj = max(min(-abs(mod(t * 6., 6.) - 3.) + 2., 1.), 0.);
    //tj = pow(tj, 2.);
    float tj = (sin(t * 5.) + 1.) /2.;
    fill += ringSector(0.3, 0.01, 0.5 - tj * 0.08, 0.025, puv);
    fill += ringSector(0.29, 0.002, 0.4 + tj * 0.025, 0.01, puv);
    fill += ringSector(0.31, 0.002, 0.225 + tj * 0.2, 0.075, puv);
    */

    // small gear
    fill2 += slantedRing(0.35, 0.025, 0.0025, -t * 0.3, 3, 0.57, 0.6, 0., 1., puv);
    //fill += ringSectors(0.38, 0.01, t * 0.02, 1., 100, 0.2, puv);
    fill2 += slantedRing(0.395, 0.0125, 0.00125, t * 0.3, 6, 0.57, 0.6, 1., 0., puv);

    // barcode
    fill += randSectors(0.45, 0.015, t * 0.1, 0.001, 50, 1., puv);
    fill += randSectors(0.45, 0.015, -t * 0.1, 0.001, 50, 1.5, puv);

    // trinity
    fill += ringSectors(0.550, 0.0025, -t * 0.9, 1.0, 3, 0.3, puv);
    fill += ringSectors(0.560, 0.0025, -t * 0.9, 1.0, 3, 0.3, puv);
    fill += ringSector(0.555, 0.0025, t * 2.4, 0.15, puv);

    // huge gear
    float gt = t * 0.05;
    fill += slantedRing(0.635, 0.01, 0., gt, 50, 0.4, 0.6, 0., 1., puv);
    fill += slantedRing(0.675, 0.01, 0., gt, 5, 0.5, 0.55, 1., 0., puv);
    fill += slantedRing(0.700, 0.01, 0., gt + 0.1, 5, 0.5, 0.55, 0., 1., puv);
    fill += slantedRing(0.740, 0.01, 0., gt, 50, 0.4, 0.6, 1., 0., puv);
    fill += ringSector(0.655, 0.02, gt, 1., puv);
    fill += ringSector(0.720, 0.02, gt, 1., puv);
    fill -= ringSectors(0.67, 0.0025, gt + 0.1, 1., 5, 0.4, puv);
    fill -= ringSectors(0.705, 0.0025, gt, 1., 5, 0.4, puv);
    fill -= ringSectors(0.63, 0.00125, gt, 1., 50, 0.3, puv);
    fill -= ringSectors(0.745, 0.00125, gt, 1., 50, 0.3, puv);

    fragColor = vec4(mainColor * fill / 5. + secondaryColor * fill2 / 5., 1.0);
}