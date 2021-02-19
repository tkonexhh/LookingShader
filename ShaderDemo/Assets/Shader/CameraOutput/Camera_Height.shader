Shader "Unlit/Camera_Height"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)


            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            
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
                // float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                // return var_MainTex ;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_MainTex, input.uv);
                // return depth ;
                float linearDepth = LinearEyeDepth(depth, _ZBufferParams);//Linear01Depth LinearEyeDepth
                return linearDepth;
                // linearDepth *= 100;
                return float4(linearDepth, linearDepth, linearDepth, 1);//float4(1, 0, 0, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
