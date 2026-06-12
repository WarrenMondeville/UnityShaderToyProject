#include "../ShaderToyTools.cginc"
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
/**

     __ __ __   ________   ___   __    _______      ______   ______   ________   ______   ______
    /_//_//_/\ /_______/\ /__/\ /__/\ /______/\    /_____/\ /_____/\ /_______/\ /_____/\ /_____/\
    \:\\:\\:\ \\::: _  \ \\::\_\\  \ \\::::__\/__  \::::_\/_\:::_ \ \\::: _  \ \\:::__\/ \::::_\/_
     \:\\:\\:\ \\::(_)  \ \\:. `-\  \ \\:\ /____/\  \:\/___/\\:(_) \ \\::(_)  \ \\:\ \  __\:\/___/\
      \:\\:\\:\ \\:: __  \ \\:. _    \ \\:\\_  _\/   \_::._\:\\: ___\/ \:: __  \ \\:\ \/_/\\::___\/_
       \:\\:\\:\ \\:.\ \  \ \\. \`-\  \ \\:\_\ \ \     /____\:\\ \ \    \:.\ \  \ \\:\_\ \ \\:\____/\
        \_______\/ \__\/\__\/ \__\/ \__\/ \_____\/     \_____\/ \_\/     \__\/\__\/ \_____\/ \_____\/


        Wang Tile Experiments | @pjkarlik

        I've wanted to try more than truchets for a while and
        something about wang tiles variations seem really
        exciting to me.

        Most of this learned from picking apart Shane and Demofox's
        examples on wang tiles. Code needs optimization but first
        attempt at doing them,

        https://www.shadertoy.com/view/ttsXW7
        https://www.shadertoy.com/view/MssSWs
*/



void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    float offset[3] = float[](0.001, 1.163, 3.271);
    float weight[3] = float[](0.2, 0.3, 0.07);


    vec2 uv = fragCoord.xy / iResolution.xy;

    vec3 og = texture(iChannel0, uv).rgb;
    vec3 tc = texture(iChannel0, uv).rgb * weight[0];
    for (int i = 1; i < 3; i++) {
        tc += texture(iChannel0, uv + vec2(offset[i]) / iResolution.xy, 0.0).rgb * weight[i];
        tc += texture(iChannel0, uv - vec2(offset[i]) / iResolution.xy, 0.0).rgb * weight[i];
    }

    // cheap distance effect for tilt/shift
    float dt = distance(uv.y - .1, .5) * 1.5;
    dt = smoothstep(.1, .6, dt);
    tc = mix(tc, og, 1. - dt);
    fragColor = vec4(pow(tc, vec3(0.4545)), 1.0);
}

