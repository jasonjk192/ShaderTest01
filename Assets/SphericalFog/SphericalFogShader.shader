Shader "ShaderTest/SphericalFogShader"
{
    Properties
    {
        _FogCenter("Fog Center/Radius", Vector) = (0,0,0,0.5)
        _FogColor("Fog Color", Color) = (1,1,1,1)
        _InnerRatio("Inner Ratio", Range(0.0,0.9)) = 0.5
        _Density("Fog Density", Range(0.0,1.0)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off Lighting Off ZWrite Off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float CalculateFogIntensity(float3 sphereCenter, float sphereRadius, float innerRatio, float density, float3 cameraPos, float3 viewDir, float maxDistance)
            {
                // Calculating intersection of ray on sphere

                float3 localCam = cameraPos - sphereCenter;
                float a = dot(viewDir, viewDir);                                    // a = D * D
                float b = 2 * dot(viewDir, localCam);                               // b = 2 * camera * D
                float c = dot(localCam, localCam) - sphereRadius * sphereRadius;    // c = camera * camera - R * R

                float d = b*b - 4*a*c;
                if(d <= 0.0f)
                    return 0;

                float DSqrt = sqrt(d);
                float d1 = max((-b - DSqrt) / 2*a, 0);
                float d2 = max((-b + DSqrt) / 2*a, 0);

                float backDepth = min(maxDistance, d2);
                float currentDepth = d1;
                int step_size = 10;
                float step_distance = (backDepth - d1) / step_size;
                float step_contribution = density;

                float centerValue = 1 / (1 - innerRatio);
                float clarity = 1;

                // Ray march into the sphere to determine fog value (clarity)

                for(int segment = 0; segment < step_size; segment++)
                {
                    float3 position = localCam + viewDir * currentDepth;
                    float val = saturate(centerValue * (1 - length(position)/sphereRadius));
                    float fog_amount = saturate(val * step_contribution);
                    clarity *= 1 - fog_amount;
                    currentDepth += step_distance;
                }

                return 1 - clarity;
            }

            struct v2f
            {
                float3 viewDir : TEXCOORD0;
                float4 clipPos : SV_POSITION;
                float4 projPos : TEXCOORD1;
            };

            float4 _FogCenter;
            fixed4 _FogColor;
            float _InnerRatio;
            float _Density;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata_base v)
            {
                v2f o;
                float4 wPos = mul(unity_ObjectToWorld, v.vertex);
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.viewDir = wPos.xyz - _WorldSpaceCameraPos;
                o.projPos = ComputeScreenPos(o.clipPos);

                float inFrontOf = (o.clipPos.z/o.clipPos.w) > 0;
                o.clipPos.z *= inFrontOf;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                half4 col = half4(1,1,1,1);
                float depth = LinearEyeDepth (UNITY_SAMPLE_DEPTH (tex2Dproj (_CameraDepthTexture, UNITY_PROJ_COORD (i.projPos))));
                float3 viewDir = normalize(i.viewDir);

                col.rgb = _FogColor.rgb;
                col.a = CalculateFogIntensity(
                    _FogCenter.xyz, _FogCenter.w, _InnerRatio, _Density, _WorldSpaceCameraPos, viewDir, depth
                    );

                return col;
            }
            ENDCG
        }
    }
}
