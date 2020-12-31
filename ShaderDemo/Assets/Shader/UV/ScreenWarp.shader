
Shader "XHH/ScreenWarp"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
        _WarpMidVal ("扭曲中值", Range(0, 1)) = 0.5
        _WarpInt ("扭曲强度", Range(0, 5)) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend one OneMinusSrcAlpha
            Cull Back
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../CustomHlsl/CustomHlsl.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _WarpInt, _WarpMidVal;

            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraColorTexture);SAMPLER(sampler_CameraColorTexture);
            
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


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float2 screenUV = input.positionCS.xy / _ScreenParams.xy;
                screenUV += (var_MainTex.r - _WarpMidVal) * _WarpInt;
                
                half4 var_CameraTex = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, screenUV);
                float3 finalRGB = var_CameraTex.rgb;
                return float4(finalRGB * var_MainTex.a * 0.5, var_MainTex.a);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
