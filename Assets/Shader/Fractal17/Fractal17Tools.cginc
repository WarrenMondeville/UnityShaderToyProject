#include "../ShaderToyTools.cginc"
// thanks FabriceNeyret2


#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)cos(h*6.3+vec3(0,23,21))*.5+.5
void mainImage(out vec4 O, vec2 C)
{
    O-=O;
    vec3 r=iResolution,p;
    for(float i=0.,g,e,l,s;
        ++i<99.;
        (e<.003)?O.xyz+=mix(r/r,cos(vec3(8,3,12)+g*(3.+sin(iTime*8.)*.2))*.5+.5,.8)*.9/i:p
    )
    {
        p=g*vec3((C-.5*r.xy)/r.y,1);
        p.z-=2.5;
        p=R(p,normalize(vec3(1,3,3)),iTime*.2);
        p=abs(p)+.2;
        p.y>p.x?p=p.yxz:p;
        p.z>p.x?p=p.zyx:p;
        p.y>p.z?p=p.xzy:p;
        s=2.;
        for(int j;j++<4;)
            p=abs(p),
            s*=l=2./min(dot(p,p),.8),
            p=p*l-vec3(2,1,3);
        g+=e=length(p.xz)/s;
    }
    O.xyz=pow(O.xyz,vec3(.8,.9,1.3));
}
