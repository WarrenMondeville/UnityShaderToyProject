# CODEBUDDY.md This file provides guidance to CodeBuddy when working with code in this repository.

## Project Overview

Unity ShaderToy Project - A collection of Shadertoy shaders ported to Unity. This project contains 150+ shader effects ported from [Shadertoy.com](https://www.shadertoy.com), demonstrating various GPU rendering techniques including raymarching, fractals, noise functions, and procedural art.

**Unity Version**: 2022.3.62t8 (Tuanjie Editor)

## Architecture

### Shader Organization

Each shader effect resides in its own folder under `Assets/Shader/`:
```
Assets/Shader/
├── ShaderToyTools.cginc     # Common GLSL→HLSL mappings
├── BufferA.renderTexture    # Render textures for buffer system
├── [ShaderName]/
│   ├── [ShaderName].shader           # Unity shader wrapper
│   ├── [ShaderName]Tools.cginc      # Ported Shadertoy code
│   ├── [ShaderName]BufferA.shader   # (Optional) Buffer pass
│   ├── [ShaderName]BufferATools.cginc
│   └── [ShaderName].mat             # Material asset
```

### Key Components

1. **ShaderToyTools.cginc** - Root include file providing GLSL to HLSL translations:
   - Type mappings (`vec3` → `float3`, `mat4` → `float4x4`)
   - Function mappings (`fract` → `frac`, `mix` → `lerp`, `texture` → `tex2D`)
   - Custom `mod()` and `smoothstep()` implementations
   - Shadertoy uniforms: `iTime`, `iFrame`, `iResolution`, `iMouse`, `iChannel0-3`

2. **ShaderManager.cs** - Manages shader effect switching in scene:
   - Attach to GameObject with child objects containing different shader materials
   - Press `W` for previous effect, `S` for next effect

3. **ShaderToyBuffer.cs** - Handles multi-buffer shader effects:
   - Supports up to 4 buffers (BufferA-D)
   - Each buffer can have 4 input channels (iChannel0-3)
   - Uses CommandBuffer for render-to-texture pipeline
   - Sets Shadertoy-compatible globals: `iTimeDelta`, `iDate`, `iMouse`, `iFrame`

### Shader Porting Pattern

The `.shader` file is a template that:
1. Includes `UnityCG.cginc` and the effect's `Tools.cginc`
2. Defines vertex/fragment shaders with standard Unity semantics
3. Calls `mainImage(col, i.uv.xy * _ScreenParams.xy)` in fragment shader

The `Tools.cginc` file contains:
1. `#include "../ShaderToyTools.cginc"` to pull in common mappings
2. Ported Shadertoy code with `mainImage()` function
3. Helper functions (noise, FBM, SDFs, etc.)

## Development Commands

### Opening the Project
- Open `UnityShaderToyProject` folder in Unity Hub/Editor (Unity 2022.3.x required)

### Running Shaders
- Open `Assets/Scenes/SampleScene.unity`
- Enter Play Mode to view shaders
- Use `W`/`S` keys to cycle through effects (requires ShaderManager setup)

### Adding a New Shader
1. Create folder: `Assets/Shader/[ShaderName]/`
2. Create shader file using existing shader as template
3. Create `Tools.cginc` with ported `mainImage()` function
4. Create material, assign shader
5. Add to scene under ShaderManager GameObject

### Multi-Buffer Shaders
- Create Buffer render textures (use provided `BufferA-D.renderTexture` as templates)
- Create Buffer shaders following `BlueCloudsBufferA.shader` pattern
- Attach `ShaderToyBuffer.cs` to camera or quad
- Assign materials and buffer textures in inspector

## Important Notes

- **Render Pipeline**: Built-in Render Pipeline (not URP/HDRP)
- **Shader Language**: CG/HLSL (`.shader` + `.cginc` includes)
- **Buffer System**: Uses `CommandBuffer` Blit operations, not Compute Shaders
- **iTime**: Mapped to `_Time.y` (Unity's time variable)
- **Texture Sampling**: Uses `tex2D` (not `tex2Dlod`) for iChannel sampling
- **Library Folder**: Excluded from version control (standard Unity .gitignore)

## Common Porting Issues

1. **GLSL Functions**: Ensure `ShaderToyTools.cginc` mappings cover all used functions
2. **Texture Access**: `texelFetch` in GLSL needs different approach in HLSL
3. **Buffer Dependencies**: Buffer shaders read from previous frame's render texture
4. **Mouse Input**: `iMouse` format is `(x, y, leftClick, rightClick)` as `Vector4`
5. **Screen Params**: `iResolution` maps to `_ScreenParams` (not `_ScreenParams.xy` alone)
