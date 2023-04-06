Shader "ShaderTest/RayMarchSphere"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"}

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 worldPos : TEXCOORD0;
                float4 clipPos : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            #define STEPS 64
            #define STEP_SIZE 0.01

            float3 sphereCenter = float3(0,0,0);

            bool SphereHit(float3 pos, float3 center, float radius)
            {
                return distance(pos, center) < radius;
            }

            float3 RaymarchHit(float3 position, float3 direction)
            {
                for(int i = 0; i < STEPS; i++)
                {
                    if(SphereHit(position, sphereCenter, 0.5))
                        return position;
                    position += direction * STEP_SIZE;
                }
                return float3(0,0,0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewDIr = normalize(i.worldPos - _WorldSpaceCameraPos);
                float3 depth = RaymarchHit(i.worldPos, viewDIr);

                half3 worldNormal = depth - sphereCenter;
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz)); 

                if(length(depth) != 0)
                {
                    depth *= nl * _LightColor0;
                    return fixed4(depth.x, depth.y, depth.z, 1);
                }
                    
                return fixed4(1,1,1,0);
            }
            ENDCG
        }
    }
}
