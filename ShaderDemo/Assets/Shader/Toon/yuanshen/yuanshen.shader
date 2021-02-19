
Shader "XHH/Toon/Yuanshen"
{
    Properties
    {
        [Header(Base Color)]
        _BaseMap ("BaseMap", 2D) = "white" { }
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)

        [Header(Alpha)]
        [Toggle(_UseAlphaClipping)]_UseAlphaClipping ("_UseAlphaClipping", Float) = 0
        _Cutoff ("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5


        [Header(Lighting)]
        _CelShadeMidPoint ("_CelShadeMidPoint", Range(-1, 1)) = -0.5
        _CelShadeSoftness ("_CelShadeSoftness", Range(0, 1)) = 0.05
        _MainLightIgnoreCelShade ("_MainLightIgnoreCelShade", Range(0, 1)) = 0

        [Header(RimLight)]
        [HDR]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimMin ("Rim Min", Range(0, 1)) = 0.1
        _RimMax ("Rim Max", Range(0, 1)) = 0.7
        _RimSmooth ("Rim Smooth", Range(0, 1)) = 0.5

        [Header(Outline)]
        _OutlineWidth ("_OutlineWidth (World Space)", Range(0, 4)) = 0.002
        _OutlineColor ("_OutlineColor", Color) = (0.5, 0.5, 0.5, 1)
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        HLSLINCLUDE
        #pragma shader_feature_local_fragment _UseAlphaClipping
        ENDHLSL
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            Blend One Zero
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            
            #include "yuanshenBasePass.HLSL"
            
            
            ENDHLSL
            
        }

        Pass
        {
            Name "Outline"

            Cull Front
            ZWrite On
            ZTest LEqual
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
            float4 _OutlineColor;
            float _OutlineWidth;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 normalWS: NORMAL;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                // input.positionOS.xyz += normalize(input.normalOS) * _OutlineWidth;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                float2 offset = TransformWorldToHClipDir(output.normalWS).xy;
                output.positionCS.xy += offset * _OutlineWidth * output.positionCS.w;
                return output;
            }

            float4 frag(Varyings input): SV_Target
            {
                return _OutlineColor;
            };
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
