Shader "ShaderTest/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_RampTex ("Ramp Texture", 2D) = "white"{}
        _OutlineColor ("Outline Color", Color) =  (0,0,0,1)
        _OutlineSize ("Outline Size", Range(0.002, 0.5)) = 0.005
		_Color  ("Color", Color) = (1,1,1,1)
    }

    SubShader
	{
      CGPROGRAM
		#pragma surface surf ToonRamp

		float4 _Color;
		sampler2D _RampTex;
		sampler2D _MainTex;
		
		float4 LightingToonRamp (SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			float diff = dot (s.Normal, lightDir);
			float h = diff * 0.5 + 0.5;
			float2 rh = h;
			float3 ramp = tex2D(_RampTex, rh).rgb;
			
			float4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * (ramp);
			c.a = s.Alpha;
			return c;
		}

		struct Input 
		{
			float2 uv_MainTex;
		};

		void surf (Input IN, inout SurfaceOutput o) 
		{			
			float4 texColor = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = (_Color * texColor).rgb;
		}
		
		ENDCG

      Pass
	  {
			Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
				
			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
			};
			
			float _OutlineSize;
			float4 _OutlineColor;
			
			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				float3 norm   = normalize(mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal));
				float2 offset = TransformViewToProjection(norm.xy);

				o.pos.xy += offset * o.pos.z * _OutlineSize;
				o.color = _OutlineColor;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return i.color;
			}
			ENDCG
		}

    } 
    Fallback "Diffuse"
}
