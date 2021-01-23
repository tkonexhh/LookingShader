#ifndef TOON_BASE_PASS_INCLUDED
    #define TOON_BASE_PASS_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


    CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float _Cutoff;

    float _CelShadeMidPoint, _CelShadeSoftness;
    float _MainLightIgnoreCelShade;

    //outline
    float _OutlineWidth;
    half3 _OutlineColor;
    CBUFFER_END

    sampler2D _BaseMap;
    
    struct Attributes
    {
        float4 positionOS: POSITION;
        float2 uv: TEXCOORD0;
        float3 normalOS: NORMAL;
    };


    struct Varyings
    {
        float4 positionCS: SV_POSITION;
        float2 uv: TEXCOORD0;
        float3 normalWS: NORMAL;
    };

    struct ToonSurfaceData
    {
        half3 albedo;
        half alpha;
    };

    struct LightingData
    {
        float3 normalWS;
    };


    Varyings vert(Attributes input)
    {
        Varyings output;
        output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
        output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
        output.uv = input.uv;


        return output;
    }



    ///////////
    half4 GetFinalBaseColor(Varyings input)
    {
        return tex2D(_BaseMap, input.uv) * _BaseColor;
    }

    void DoClipTestToTargetAlpha(half alpha)
    {
        #if _UseAlphaClipping
            clip(alpha - _Cutoff);
        #endif
    }

    ToonSurfaceData InitSurfaceData(Varyings input)
    {
        ToonSurfaceData output;
        float4 baseColor = GetFinalBaseColor(input);
        output.albedo = baseColor.rgb;
        output.alpha = baseColor.a;
        DoClipTestToTargetAlpha(output.alpha);
        return output;
    }

    LightingData InitLightintData(Varyings input)
    {
        LightingData output;
        output.normalWS = normalize(input.normalWS);
        return output;
    }

    half3 ShadeLight(ToonSurfaceData surfaceData, LightingData lightingData, Light light)
    {
        half3 N = lightingData.normalWS;
        half3 L = light.direction;

        half NdotL = dot(N, L);
        half lightAttenutaion = 1;
        //根据NdotL 柔化 阴影边缘
        half celShadeResult = smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NdotL);
        lightAttenutaion *= lerp(celShadeResult, 1, _MainLightIgnoreCelShade);
        return lightAttenutaion * light.color  ;
    }

    half3 ShadeMainlight(ToonSurfaceData surfaceData, LightingData lightingData, Light light)
    {
        return ShadeLight(surfaceData, lightingData, light);
    }

    half3 ShadeLights(ToonSurfaceData surfaceData, LightingData lightingData)
    {
        Light mainLight = GetMainLight();

        half3 mainLightResult = ShadeMainlight(surfaceData, lightingData, mainLight);

        return mainLightResult;
    }




    float4 frag(Varyings input): SV_Target
    {
        ToonSurfaceData surfaceData = InitSurfaceData(input);
        LightingData lightingData = InitLightintData(input);

        half3 color = surfaceData.albedo * ShadeLights(surfaceData, lightingData);

        return float4(color, surfaceData.alpha);
    }
    

#endif