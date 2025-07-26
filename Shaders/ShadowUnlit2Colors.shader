Shader "ToyShader/ShadowUnlit2Colors"
{
    Properties
    {
        _TopColor ("Top Color", Color) = (1,1,1,1)
        [MainColor] _Color ("Main Color", Color) = (1,1,1,1)
        _TopAmount ("Top Amount", Float) = 0.2
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
            
            float4 _TopColor;
            float4 _Color;
            float _TopAmount;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                VertexNormalInputs normals = GetVertexNormalInputs(IN.normal);
                OUT.normalWS =  normals.normalWS;
                // shadow
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionWS = positions.positionWS;
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half topRatio = 1 - (dot(IN.normalWS, float3(0, 1, 0)) + 1) * 0.5;
                half4 color = lerp(_TopColor, _Color, step(_TopAmount, topRatio));
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
