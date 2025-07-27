#ifndef TOYSHADER_SHADOW_INCLUDED
#define TOYSHADER_SHADOW_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

half CalculateShadow(float3 positionWS, half3 normalWS)
{
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    float shadowAmount = MainLightRealtimeShadow(shadowCoord);
    float shadowFade = GetMainLightShadowFade(positionWS);
    float lighting = step(0.95, lerp(shadowAmount, 1, shadowFade));
    Light light = GetMainLight();
    float surfaceShadow = clamp(step(0.1, dot(normalWS, light.direction)), 0, 1);
    lighting = min(lighting, surfaceShadow);
    lighting = max(lighting, 1 - _MainLightShadowParams.x);
    return lighting;
}

#endif