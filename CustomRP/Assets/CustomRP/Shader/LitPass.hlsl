﻿#ifndef CUSTOM_LIT_PASS_INCLUDED
    #define CUSTOM_LIT_PASS_INCLUDED

    #include "../ShaderLibrary/Common.hlsl"
    #include "../ShaderLibrary/Surface.hlsl"
    #include "../ShaderLibrary/Shadows.hlsl"
    #include "../ShaderLibrary/Light.hlsl"
    #include "../ShaderLibrary/BRDF.hlsl"
    #include "../ShaderLibrary/Lighting.hlsl"
    
    // CBUFFER_START(UnityPerMaterial)
    // float4 _BaseColor;
    // CBUFFER_END


    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
    UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
    UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
    UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

    struct Attributes
    {
        float3 positionOS: POSITION;
        float2 uv: TEXCOORD0;
        float3 normalOS: NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS: SV_POSITION;
        float3 positionWS: VAR_POSITION;
        float2 uv: VAR_UV;
        float3 normalWS: VAR_NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings LitPassVertex(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
        output.positionCS = TransformWorldToHClip(output.positionWS);
        output.normalWS = TransformObjectToWorldNormal(input.normalOS);
        float4 baseMapST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
        output.uv = input.uv * baseMapST.xy + baseMapST.zw;
        return output;
    }

    float4 LitPassFragment(Varyings input): SV_TARGET
    {
        UNITY_SETUP_INSTANCE_ID(input);
        float4 baseColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
        float4 var_BaseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
        float4 base = var_BaseMap * baseColor;
        // return base.a;
        #ifdef _CLIPPING
            clip(base.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
        #endif
        

        Surface surface;
        surface.positionWS = input.positionWS;
        surface.normal = normalize(input.normalWS);
        surface.viewDir = normalize(_WorldSpaceCameraPos - input.positionWS);
        surface.depth = -TransformWorldToView(input.positionWS).z;//变化到相机下的Z轴，因为相机变化是看向-Z轴的 这里--+ 得到正Z值
        surface.color = base.rgb;
        surface.alpha = base.a;
        surface.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
        surface.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
        #ifdef _PREMULTIPLY_ALPHA
            BRDF brdf = GetBRDF(surface, true);
        #else
            BRDF brdf = GetBRDF(surface);
        #endif
        float3 lighting = GetLighting(surface, brdf);

        return float4(lighting, surface.alpha);
    }

#endif