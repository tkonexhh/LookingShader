
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"

float remap(float target, float oldMin, float oldMax, float newMin, float newMax)
{
    return(target - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin;
}

float2 remap(float2 target, float oldMin, float oldMax, float newMin, float newMax)
{
    target.x = remap(target.x, oldMin, oldMax, newMin, newMax);
    target.y = remap(target.y, oldMin, oldMax, newMin, newMax);
    return target;//(target-oldMin)/(oldMax-oldMin)*(newMax-newMin)+newMin;
}

float sqr(float num)
{
    return num * num;
}



float4x4 GetObjectToViewMatrix()
{
    return UNITY_MATRIX_MV;//mul(UNITY_MATRIX_V, UNITY_MATRIX_M)
}

// Tranforms position from view space to homogenous space
float3 TransformObjectToView(float3 positionOS)
{
    return mul(GetObjectToViewMatrix(), float4(positionOS, 1.0)).xyz;
}
