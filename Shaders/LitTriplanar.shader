Shader "ToyShader/LitTriplanar"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _Color ("Main Color", Color) = (1,1,1,1)
        [KeywordEnum(OBJECT, WORLD)] _COORD_SPACE ("Space", Float) = 0
        _Tiling ("Tiling", Float) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque"  "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile _COORD_SPACE_OBJECT _COORD_SPACE_WORLD

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Utils/SHADOW.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS : TEXCOORD;
                half3 normalWS : TEXCOORD1;

                #ifdef _COORD_SPACE_OBJECT
                    half3 normalOS : TEXCOORD2;
                    half3 coords : TEXCOORD3;
                #endif
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _Color;
            float _Tiling;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // triplanar
                #ifdef _COORD_SPACE_OBJECT
                    OUT.normalOS = IN.normalOS;
                    OUT.coords = IN.positionOS.xyz * _Tiling;
                #endif
                
                // shadow
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // triplanar
                half3 normal;
                #ifdef _COORD_SPACE_OBJECT
                    normal = abs(IN.normalOS);
                #else
                    normal = abs(IN.normalWS);
                #endif

                half3 blend = abs(normal);
                blend /= dot(blend, 1.0);
                half3 coords;
                #ifdef _COORD_SPACE_OBJECT
                    coords = IN.coords;
                #else
                    coords = IN.positionWS;
                #endif
                
                half4 cx = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, coords.yz);
                half4 cy = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, coords.xz);
                half4 cz = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, coords.xy);
                half4 color = cx * blend.x + cy * blend.y + cz * blend.z;
                color *= _Color;
                
                // shadow
                color *= CalculateShadow(IN.positionWS, IN.normalWS);
                
                return color;
            }
            
            ENDHLSL
        }

        UsePass "ToyShader/Lit/ShadowCaster"
    }
}
