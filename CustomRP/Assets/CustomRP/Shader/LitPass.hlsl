#ifndef CUSTOM_LIT_PASS_INCLUDED
    #define CUSTOM_LIT_PASS_INCLUDED

    #include "../ShaderLibrary/Common.hlsl"
    #include "../ShaderLibrary/Surface.hlsl"
    #include "../ShaderLibrary/Light.hlsl"
    #include "../ShaderLibrary/Lighting.hlsl"
    
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
        float3 normalOS: NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS: SV_POSITION;
        float2 uv: VAR_UV;
        float3 normalWS: VAR_NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings LitPassVertex(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_TRANSFER_INSTANCE_ID(input, output);
        float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
        output.positionCS = TransformWorldToHClip(positionWS);
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
        #ifdef _CLIPPING
            clip(base.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
        #endif
        

        Surface surface;
        surface.normal = normalize(input.normalWS);
        surface.color = base.rgb;
        surface.alpha = base.a;

        float3 lighting = GetLighting(surface);

        return float4(lighting, surface.alpha);
    }

#endif