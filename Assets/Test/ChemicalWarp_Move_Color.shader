Shader "GiraffeShader/ChemicalWarp_Move_Color" {
	Properties{
		_MainTex("Main Tex", 2D) = "white" {}
		//玻璃的法线纹理
		_BumpMap("Normal Map", 2D) = "bump" {}
		//折射图扭曲程度
		_Distortion("Distortion", Range(0, 10000)) = 10
		//折射效果
		_RefractAmount("Refract Amount", Range(0.0, 1.0)) = 0.5
		//流动速度
		_WaveSpeed("WaveSpeed",Range(-2.0, 2.0)) = 1
		//附加颜色
		_AdditionColor("AdditionColor",Color) = (1,1,1,1)
		//水面偏移比例
		_LevelOfWaterOffsetScale("LevelOfWaterOffsetScale",Range(-1,1)) = 0
		//水平面高度X
		_LevelOfWaterX("LevelOfWaterX",float) = 0
		//水平面高度Y
		_LevelOfWaterY("LevelOfWaterY",float) = 0
		//水平面高度Z
		_LevelOfWaterZ("LevelOfWaterZ",float) = 0
	}
	SubShader{
		// 因为玻璃的，这里我们需要做透明混合
		Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }
		Cull Off
		//关闭深度写入
		//ZWrite off
		//源因子：透明度            目标因子：1-源因子透明度
		//最后会把源因子和目标因子相乘得到最终结果
		//Blend SrcAlpha OneMinusSrcAlpha
		//这是一个抓取屏幕图像的Pass,会把图像存进_RefractionTex这个变量中
		GrabPass { "_RefractionTex" }

		Pass {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			float _WaveSpeed;
			float4 _AdditionColor;
			float _LevelOfWaterOffsetScale;
			float _LevelOfWaterX;
			float _LevelOfWaterY;
			float _LevelOfWaterZ;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord: TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
				float4 objpos:TEXCOORD5;
			};

			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				//TRANSFORM_TEX 想当于 v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				//世界空间下顶点位置
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//世界空间下法线位置
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				//世界空间下切线位置
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				//世界空间副切线位置
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				//这里的TtoW0、TtoW1、TtoW2 的xyz列排构成了一个转置到世界空间的矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				o.objpos = v.vertex;

				//齐次坐标系下的屏幕坐标值
				o.scrPos = ComputeGrabScreenPos(o.pos);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target {

				//世界坐标下的位置第一组纹理坐标的分量
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

				//float3 unreal = float3(_LevelOfWaterX,_LevelOfWaterY,_LevelOfWaterZ);a
				//float curHeight= UnityWorldToObjectDir(unreal).y;
				//与中心点距离（_LevelOfWaterOffsetScale是有正负值的摆动比例）
				float centerDistance = (worldPos.x - _LevelOfWaterX) * _LevelOfWaterOffsetScale;
				//波动值影响裁剪高度
				float heightOffset = _LevelOfWaterY + centerDistance + sin(_Time.y * 10 + (worldPos.x + worldPos.z)*10) * 0.1;
				//高于指定高度则裁剪
				if (worldPos.y > heightOffset)
				{
					clip(-1);
				}
				fixed3 worldViewDir = normalize(worldPos - _WorldSpaceCameraPos);
				float tLen = heightOffset - _WorldSpaceCameraPos.y;
				float3 tWorldPos = _WorldSpaceCameraPos.xyz + worldViewDir * (tLen / worldViewDir.y);
				float2 tIndexXZ = floor(tWorldPos.xz/ 1);
				float tIndex = fmod(tIndexXZ.x + tIndexXZ.y, 2);
				return tIndex;

				i.uv.z += _SinTime.x * _WaveSpeed;
				i.uv.w -= _CosTime.x * _WaveSpeed;

				// 取切线空间中的法线
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

				// 计算切线空间中的偏移
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;

				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

				// 把法线转到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				//反射光计算 根据入射光方向，和顶点法向量，计算反射光方向向量。
				fixed3 reflDir = reflect(-worldViewDir, bump);
				//取主图颜色
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);

				//调节一下扭曲的程度,得到最终的颜色
				fixed3 finalColor = texColor * (1 - _RefractAmount) + refrCol * _RefractAmount;
				finalColor *= _AdditionColor;

				return fixed4(finalColor, 1);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}