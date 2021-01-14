﻿#ifndef CUSTOM_UNLIT_PASS_INCLUDED
    #define CUSTOM_UNLIT_PASS_INCLUDED

    #include "../ShaderLibrary/Common.hlsl"
    
    // CBUFFER_START(UnityPerMaterial)
    // float4 _BaseColor;
    // CBUFFER_END



    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    // float4 _BaseColor;
    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

    struct Attributes
    {
        float3 positionOS: POSITION;
        float2 uv: TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS: SV_POSITION;
        float2 uv: TEXCOORD0;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings UnlitPassVertex(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
        output.positionCS = TransformWorldToHClip(positionWS);
        float4 baseMapST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
        output.uv = input.uv * baseMapST.xy + baseMapST.zw;
        return output;
    }

    float4 UnlitPassFragment(Varyings input): SV_TARGET
    {
        UNITY_SETUP_INSTANCE_ID(input);
        float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
        float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
        float4 base = var_BaseMap * baseColor;
        #ifdef _CLIPPING
            clip(base.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
        #endif
        return base;
    }

#endif