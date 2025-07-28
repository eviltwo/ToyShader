Shader "ToyShader/Lit2Colors"
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
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

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
                float3 positionWS : TEXCOORD0;
                half3 normalWS : TEXCOORD1;
            };
            
            float4 _TopColor;
            float4 _Color;
            float _TopAmount;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS =  TransformObjectToWorldNormal(IN.normalOS);
                // shadow
                OUT.positionWS = TransformObjectToWorld(IN.positionOS);
                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half topRatio = 1 - (dot(IN.normalWS, float3(0, 1, 0)) + 1) * 0.5;
                half4 color = lerp(_TopColor, _Color, step(_TopAmount, topRatio));
                color *= CalculateShadow(IN.positionWS, IN.normalWS);
                return color;
            }
            
            ENDHLSL
        }

        UsePass "ToyShader/Lit/ShadowCaster"
    }
}
