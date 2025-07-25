Shader "ToyShader/ShadowUnlitWorldTriplanar"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [MainColor] _Color ("Main Color", Color) = (1,1,1,1)
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
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                half3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                half3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
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
                VertexNormalInputs normals = GetVertexNormalInputs(IN.normal);
                OUT.normalWS =  normals.normalWS;
                // shadow
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionWS = positions.positionWS;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // triplanar
                half3 blend = abs(IN.normalWS);
                blend /= dot(blend, 1.0);
                half4 cx = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.positionWS.yz * _Tiling);
                half4 cy = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.positionWS.xz * _Tiling);
                half4 cz = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.positionWS.xy * _Tiling);
                half4 color = cx * blend.x + cy * blend.y + cz * blend.z;
                color *= _Color;
                // shadow
                half4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                half shadowAmount = MainLightRealtimeShadow(shadowCoord);
                half shadowFade = GetMainLightShadowFade(IN.positionWS);
                return color * lerp(shadowAmount, 1, shadowFade);
            }
            
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            
            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
