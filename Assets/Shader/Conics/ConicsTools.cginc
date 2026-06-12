#include "../ShaderToyTools.cginc"
////////////////////////////////////////////////////////////////////////////////
//
// Conics through 3 points and 2 lines. mla, 2021
//
// A conic through three given points and tangent to two given lines,
// must satisfy a quartic equation, and thus there are four solutions
// (taking due account of multiple roots), though the points of tangency
// may not be real. A lovely geometric solution is given by Heinrich
// Dörrie in 100 Great Problems of Elementary Mathematics, making use
// of Desargues Involution Theorem (though Apollonius had a thing or
// two to say about all this as well).
//
// https://archive.org/details/100GreatProblemsOfElementaryMathematicsDoverHeinrichDrrie/page/n281/
//
// The white conics pass through the three red points and are tangent to
// the green lines, the blue conics are tangent to the three red lines
// (dual to the red points) and pass through the green points (dual to
// the green lines).
//
// In the default configuration (see code), one of the green lines is
// the line at infinity, so cannot be seen and the white conics are all
// parabolas, with the dual blue conics all appearing as ellipses (I'll
// leave why that is so as a puzzle).
//
// The mouse sets the position of the green line. For some positions there is
// no (real) solution for the conic - I'll leave the criteria for that as
// another puzzle.
//
// A nice video from CodeParade on all this & more:
// https://www.youtube.com/watch?v=X83vac2uTUs & he has some nice code here
// (this shader uses a similar solution but was developed independently):
// https://github.com/HackerPoet/Conics
//
////////////////////////////////////////////////////////////////////////////////

#define PI 3.141592654
#define configuration 2

float lwidth = 0.015;
float pwidth = 0.05;
#define scale 2.5

#define background vec3(0,0,0)//vec3(1,1,0.5);
#define pcolor0 vec3(1, 0, 0)
#define pcolor1 vec3(0, 1, 0)
#define pcolor2 vec3(1, 1, 0)
#define pcolor3 vec3(0, 1, 1)
#define lcolor0 vec3(1, 0, 0)
#define lcolor1 vec3(0, 1, 0)
#define lcolor2 vec3(1, 1, 0)
#define ccolor0 0.8 * vec3(1, 1, 1)
#define ccolor1 vec3(0, 0, 1)

// Represent a projective conic as a 3x3 matrix:
//
// M = (a,d,e,
//      d,b,f,
//      e,f,c)
//
// is: axx + byy + czz + 2(dxy + exz + fyz) = 0
// calculated as pMp for p = (x,y,z).
//
// We can treat this as a distance field, scaled by the
// (x,y) derivative in order to get correct line widths.

// With this representation, the dual conic is just the inverse;
// if the determinant is zero then there is no dual and the
// conic is degenerate (what about adjugate?).

// The triangle of reference (ToR subsequently) is the three
// points with homogeneous coordinates (1,0,0),(0,1,0),(0,0,1)
// The ToR is mapped to any three points p,q,r by the matrix
// mat3(p,q,r) (with the usual glsl column major convention) and
// so the inverse matrix maps p,q,r to the ToR, and we can solve
// many problems more easily by first mapping selected points to
// the ToR, solving a simpler problem, and mapping back at the end.
//
// A conic through the ToR is represent by a matrix with the form
//
// C = mat3(0,d,e,
//          d,0,f,
//          e,f,0)
//
// which represents the conic with equation:
//
// dxy + ezx + fyz = 0
//
// and this can be thought of as a constraint on d,e,f for it to
// pass through the point (x,y,z)
//
// The inverse of C gives the line equation form of the conic,
// ie. vec3(l,m,n)*inverse(C)*vec3(l,m,n) = 0 just when the line
// (l,m,n) is tangent to the conic.
//
// For a conic through the ToR, the requirement that the conic is
// tangent to a line (l,m,n) simplifies to:
//
// 4mnef = (me+nf-ld)²,
//
// a quadratic constraint, so there will be 0,1, or 2 ways it can
// be satisfied in general. This constraint may be simplified if,
// for example, the line passes through a vertex of the ToR, in which
// case one of l,m,n are zero and the constraint becomes linear (if
// two are zero, then the line is a side of the ToR and the problem
// becomes even simpler).
//
// The most difficult situation is for three points and two general
// lines (or dually, three lines and two points), with two quadratic
// constraints, giving rise to a quartic equation.
//
// In this case, there is a simpler way to proceed using the
// Desargues involution theorem, for details see Dörrie, but
// briefly, the two tangent lines meet the conic at two points,
// with the tangent chord between, and the sides of the ToR meet
// the tangent chord at the fixpoints of a certain involution of
// the line (an involution is a self-inverse projective
// transformation, with t mapping to t' with tt' + b(t+t') + d = 0),
// the involution on BC, for example, takes (0,1,0) to (0,0,1) and
// (0,-n,m) to (0,-N,M) where (l,m,n) and (L,M,N) are the two lines.
// In fact, for our involutions, b = 0 and d = mM/nN for BC
// with the fixpoint being (0,1,sqrt(d)) (with no solution if d < 0)
// and similarly on AC (it's easy to see there are either 3 real
// fixpoints or 1, so we only need to calculate for two lines).

mat3 pointconic(vec3 p, vec3 P) {
    // Construct matrix for conic through vertices of ToR
    // (so diagonal is zero) and through p and P
    float x = p[0], y = p[1], z = p[2];
    float X = P[0], Y = P[1], Z = P[2];
    // Solve the homogeneous linear system
    // dxy+exz+fyz = 0
    // dXY+eXZ+fYZ = 0
    // This is just the intersection of two lines, so:
    vec3 l0 = vec3(x * y, z * x, y * z);
    vec3 l1 = vec3(X * Y, Z * X, Y * Z);
    vec3 def = cross(l0, l1);
    float d = def[0], e = def[1], f = def[2];
    return mat3(0, d, e,
        d, 0, f,
        e, f, 0);
}

bool lineconicparams(out vec2 res, vec3 a, vec3 A) {
    float l = a[0], m = a[1], n = a[2];
    float L = A[0], M = A[1], N = A[2];
    float lL = l * L, mM = m * M, nN = n * N;
    // sqrt(d) and sqrt(D) are fixpoints of the involutions
    // as described above.
    if (lL == 0.0 || mM == 0.0 || nN == 0.0) return false;
    float d = mM / nN;
    if (d < 0.0) return false;
    float D = nN / lL;
    if (D < 0.0) return false;
    res = vec2(sqrt(d), sqrt(D));
    return true;
}

mat3 cofactor(mat3 m) {
    // Cofactor matrix of m, ie. the transpose of the adjugate
    // (determinant is dot(m[0],cross(m[1],m[2])) and matrix
    // multiplication is dot products of rows and columns)
    return mat3(cross(m[1], m[2]),
        cross(m[2], m[0]),
        cross(m[0], m[1]));
}

vec3 join(vec3 p, vec3 q) {
    // Return either intersection of lines p and q
    // or line through points p and q, r = kp + jq
    return cross(p, q);
}

// Screen coords to P2 coords
vec3 map(vec2 p) {
    return vec3(scale * (2.0 * p - iResolution.xy) / iResolution.y, 1);
}

vec2 rotate(in vec2 p, in float t) {
    return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

vec3 transform(vec3 p) {
    float t = iTime;
    p.y -= 0.1;
    p.xy = rotate(p.xy, 0.2 * t);
    p.y += 0.1;
    if (false) p.yz = rotate(p.yz, 0.1618 * t);
    return p;
}

float pointdist(vec3 p, vec3 q) {
    if (p.z == 0.0 || q.z == 0.0) return 1.0;
    p /= p.z; q /= q.z; // Normalize
    return smoothstep(0.5 * pwidth, pwidth, distance(p, q));
}

float conicdist(vec3 p, mat3 m) {
    float d = dot(p, mul(m, p));
    vec3 dd = 2.0 * mul(m, p);
    d = abs(d / (p.z * length(dd.xy))); // Normalize for Euclidean distance
    return smoothstep(0.5 * lwidth, lwidth, d);
}

float linedist(vec3 p, vec3 l) {
    float k = p.z * length(l.xy);
    if (k == 0.0) return 1.0;
    float d = abs(dot(p, l) / k);
    return smoothstep(0.5 * lwidth, lwidth, d);
}

vec3 cmix(vec3 color0, vec3 color1, float level) {
    return mix(color0, color1, 1.0 - level);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    lwidth = 0.015;
    pwidth = 0.05;
    vec3 pos = map(fragCoord.xy);
    vec3 p0, p1, p2, l0, L0;
    if (configuration == 0) {
        p0 = vec3(1, 0, 0); p1 = vec3(0, 1, 0); p2 = vec3(0, 0, 1);
        l0 = vec3(1, 1, 1); L0 = vec3(1.4, 0.5, 1);
    }
    else if (configuration == 1) {
        p0 = vec3(0, 0, 1); p1 = vec3(1, 0, 1); p2 = vec3(0, 1, 1);
        l0 = vec3(1, 1, 1); L0 = vec3(1.5, 0.5, 1);
    }
    else if (configuration == 2) {
        p0 = vec3(0, 1, 1); p1 = vec3(0.866, -0.5, 1); p2 = vec3(-0.866, -0.5, 1);
        l0 = vec3(0, 0, 1); L0 = vec3(-0.8, 0, 1);
    }
    else {
        p0 = vec3(1, 0, 1);  p1 = vec3(0, 1, 1); p2 = vec3(-1, 0, 1);
        l0 = vec3(1, 1, 0); L0 = vec3(1.5, 0.618, 1);
    }
    p0 = transform(p0); p1 = transform(p1); p2 = transform(p2);
    //l0 = transform(l0); L0 = transform(L0);
    if (iMouse.x != 0.0) L0 = map(iMouse.xy);

    vec3 p01 = join(p0, p1);
    vec3 p02 = join(p0, p2);
    vec3 p12 = join(p1, p2);

    vec3 color = background;

    lwidth = max(lwidth, fwidth(length(pos)));

    // The diagonal lines of the quadrangle
    color = cmix(color, lcolor2, linedist(pos, p01));
    color = cmix(color, lcolor2, linedist(pos, p02));
    color = cmix(color, lcolor2, linedist(pos, p12));

    // The tangent lines
    color = cmix(color, lcolor1, linedist(pos, l0));
    color = cmix(color, lcolor1, linedist(pos, L0));

    // The lines of the ToR
    color = cmix(color, lcolor0, linedist(pos, p0));
    color = cmix(color, lcolor0, linedist(pos, p1));
    color = cmix(color, lcolor0, linedist(pos, p2));

    mat3 m = mat3(p0, p1, p2); // Map from ToR to (p0,p1,p2)
    if (determinant(m) != 0.0) {
        // m must be invertible
        vec3 l1 = mul(l0, m), L1 = mul(L0, m); // Map the lines
        m = m; // And invert for point mapping
        vec2 t;
        if (lineconicparams(t, l1, L1)) {  // Find involution fixpoints
            for (int i = -1; i <= 1; i += 2) {
                for (int j = -1; j <= 1; j += 2) {
                    // Each involution has two fixpoints ±t
                    // so there are 4 combinations possible
                    vec3 p = vec3(0, 1, float(i) * t[0]);
                    vec3 P = vec3(float(j) * t[1], 0, 1);
                    vec3 l = cross(p, P);  // Line though p and P
                    vec3 q = cross(l, l1); // Intersect with tangents to give points on conic
                    vec3 Q = cross(l, L1);
                    mat3 c = pointconic(q, Q); // Find conic through ToR, q and Q
                    c = transpose(m) * c * m; // Conjugate with map to ToR
                    // And draw conic and dual
                    color = cmix(color, ccolor0, conicdist(pos, c));
                    // For the dual, just use the cofactor matrix
                    color = cmix(color, ccolor1, conicdist(pos, cofactor(c)));
                }
            }
        }
    }

    color = cmix(color, pcolor2, pointdist(pos, p01));
    color = cmix(color, pcolor2, pointdist(pos, p02));
    color = cmix(color, pcolor2, pointdist(pos, p12));

    color = cmix(color, pcolor1, pointdist(pos, l0));
    color = cmix(color, pcolor1, pointdist(pos, L0));

    color = cmix(color, pcolor0, pointdist(pos, p0));
    color = cmix(color, pcolor0, pointdist(pos, p1));
    color = cmix(color, pcolor0, pointdist(pos, p2));

    fragColor = vec4(pow(color, vec3(0.4545, 0.4545, 0.4545)), 1);
}