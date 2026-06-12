#include "../ShaderToyTools.cginc"
#define NEAR 0.1
#define FAR 100.
#define ITER 128
#define PI 3.14159265

#define Tau 6.2832
#define speed .05
#define density .0000000000000001
#define shape .05

vec2 frot(vec2 p, float a) { float c = cos(a), s = sin(a);return mul(p, mat2(c, -s, s, c)); }
bool xnor(bool a, bool b) { return !(a^b); }
//bool xnor(bool a, bool b) { return !(pow(a,b)); }
bool alleq(bool a, bool b, bool c) { return xnor(a, b) && xnor(b, c) && xnor(c, a); }
bool rect(vec2 p, vec2 wh) { return abs(p.x) < abs(wh.x) && abs(p.y) < abs(wh.y); }
bool digNF(vec2 p) { return rect(p, vec2(.015, .17)); }
bool digN(vec2 p, int n) { float D = .005;bool a = digNF(p - vec2(.1 + D, .1 + D)), b = digNF(p - vec2(.1 + D, -.1 - D)), c = digNF(p - vec2(-.1 - D, .1 + D)), d = digNF(p - vec2(-.1 - D, -.1 - D)), e = digNF(frot(p, PI / 2.)), f = digNF(frot(p - vec2(0., .2 + 2. * D), PI / 2.)), g = digNF(frot(p + vec2(0., .2 + 2. * D), PI / 2.));if (n == 0) { return a || b || c || d || f || g; }if (n == 1) { return a || b; }if (n == 2) { return a || d || e || f || g; }if (n == 3) { return a || b || e || f || g; }if (n == 4) { return a || b || c || e; }if (n == 5) { return b || c || e || f || g; }if (n == 6) { return b || c || d || e || f || g; }if (n == 7) { return a || b || f; }if (n == 8) { return a || b || c || d || e || f || g; }if (n == 9) { return a || b || c || e || f || g; }return false; }
bool colon(vec2 p) { return rect(p * 3. - vec2(0., .3), .1) || rect(p * 3. - vec2(0., -.3), .1); }

float getHrs() { return mod(floor(iTime / 3600.), 24.); }
float getMns() { return mod(floor(iTime / 60.), 60.); }
float getScs() { return mod(floor(iTime), 60.); }

float random(vec2 seed) {
	return fract(sin(dot(seed.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float Cell(vec2 coord) {
	vec2 cell = fract(coord) * vec2(.5, 2.) - vec2(.1, .5);
	return (1. - length(cell * 0.5 - 0.25)) * step(random(floor(coord)), density) * 5.;
}

float sdBox(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

vec4 mapCube(vec3 pos, vec3 cl)
{
	float dist = sdBox(pos, vec3(2.0, 0.3, 10.0));
	return vec4(cl, dist);
}

float ship(vec3 p)
{
	return dot(vec3(0.9, 0.3, 0.5), abs(p)) - 1.0;
}

vec4 combine(vec4 val1, vec4 val2)
{
	if (val1.w < val2.w) return val1;
	return val2;
}

vec4 map(vec3 pos)
{
	vec4 q = vec4(pos + vec3(0, 0, -60.0 + iTime * 70.0), 1.0);
	q.z = mod(q.z, 40.0) - 20.0;

	vec4 val1 = mapCube(q.xyz + vec3(0, 0, 0.0), vec3(0.3 + pos.y + sin(iTime * 0.7), 0.5 + pos.y + sin(iTime * 0.7), 0.7 + pos.y + sin(iTime * 0.7)));

	float si = ship(pos + vec3(0, -5.0 + sin(iTime * 10.0), -50.0));
	return combine(val1, vec4(1, 1, 1, si));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

	vec2 position = (fragCoord.xy / iResolution.xy);
	position -= .5;

	vec2 rot_t = iTime + cos(iTime * 0.33) - length(position * sin(iTime * 0.21));
	mat2 rot_x = mat2(cos(rot_t.y), -sin(rot_t.x), sin(rot_t.x), cos(rot_t.y)) * 2.0;

	int sec = int(mod(iTime, 10.));

	float dir2 = 1.0;
	if (sec >= 4) {
		if (sec >= 7)
		{
			dir2 = -1.0;
		}
		position = mul(position, rot_x) * dir2;
	}

	vec3 dir = vec3(position, 1.0);
	dir = normalize(dir);

	vec3 pos = vec3(.0, 3.5, 15.0);

	vec4 result;
	for (int i = 0; i < ITER; i++)
	{
		result = map(pos);
		if (result.w < NEAR || result.w > FAR) break;
		pos += result.w * dir;
	}

	vec3 col = map(pos).xyz;
	if (pos.z > 100.)
	{
		vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
		if (sec >= 4) {
			p = mul(p, rot_x) * dir2;
		}

		p.y += 0.1;
		vec2 uv;

		float r = sqrt(dot(p, p));
		float a = atan(p.y, p.x);

		uv.x = 0.1 * (iTime * 3.0) - .1 / r;
		uv.y = 1. * a / 3.1416;

		vec2 position = floor(uv * 20.0 + sin(iTime) * 2.0) / 20.0;

		float ca = sin(3.14 * 20.0 * fract(sin(dot(position.xy, vec2(11.9898, 78.233))) * 43758.5453) + 2.0 * iTime);
		float cb = sin(3.14 * 30.0 * fract(sin(dot(position.xy, vec2(11.9898, 78.233))) * 43758.5453) + 3.0 * iTime);
		float cc = sin(3.14 * 20.0 * fract(sin(dot(position.xy, vec2(11.9898, 78.233))) * 43758.5453) + 1.0 * iTime);
		float color = ca * cb + cc - 1.0;

		// took effect from http://glslsandbox.com/e#24979.0
		float a2 = fract(atan(p.x, p.y) / Tau);
		float d = length(p);

		vec2 coord = vec2(pow(d, shape), a2) * 256.;
		vec2 delta = vec2(-iTime * speed * 256., .5);

		float c = 0.;
		coord += delta;
		c = max(c, Cell(coord));

		col = vec3(0.3 + color, 0.5 + color, 0.7 + color) + c * d;
	}
	else
	{
		vec3 lightPos = vec3(20.0, 20.0, 20.0);
		vec3 light2Pos = normalize(lightPos - pos);
		vec3 eps = vec3(.1, .01, .0);
		vec3 n = vec3(result.w - map(pos - eps.xyy).w,
			result.w - map(pos - eps.yxy).w,
			result.w - map(pos - eps.yyx).w);
		n = normalize(n);

		float lambert = max(.0, dot(n, light2Pos));
		col *= lambert;

		// specular : 
		vec3 h = normalize(-dir + light2Pos);
		float spec = max(0., dot(n, h));
		col += pow(spec, 16.);
	}

	vec2 p2 = -1.0 + 2.0 * fragCoord.xy / iResolution.xy - vec2(0.7, 1.1);
	float digT = 0.;
	digT += digN(p2 * 5. - vec2(-.2, -1.), int(fract(iTime) * 3.0)) ? 1. : 0.;
	digT += digN(p2 * 5. - vec2(.2, -1.), int(fract(iTime) * 6.0)) ? 1. : 0.;
	digT += colon(p2 * 5. - vec2(.5, -1.)) ? 1. : 0.;
	digT += digN(p2 * 5. - vec2(.8, -1.), int(fract(iTime) * 9.0)) ? 1. : 0.;
	digT += digN(p2 * 5. - vec2(1.2, -1.), int(mod(getScs(), 10.))) ? 1. : 0.;

	fragColor = vec4(col + digT, 1.0);
}