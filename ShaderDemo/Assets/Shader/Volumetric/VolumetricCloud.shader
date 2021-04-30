Shader "XHH/Volumetric/VolumetricCloud"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _UVTex ("UVTex", 2D) = "white" { }
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
            float4x4 _InverseProjectionMatrix;
            float4x4 _InverseViewMatrix;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_UVTex);SAMPLER(sampler_UVTex);
            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 viewVector: TEXCOORD1;
            };

            float4 GetWorldSpacePosition(float depth, float2 uv)
            {
                // 屏幕空间 --> 视锥空间
                float4 view_vector = mul(_InverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
                view_vector.xyz /= view_vector.w;
                //视锥空间 --> 世界空间
                float4x4 l_matViewInv = _InverseViewMatrix;
                float4 world_vector = mul(l_matViewInv, float4(view_vector.xyz, 1));
                return world_vector;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                // Camera space matches OpenGL convention where cam forward is -z. In unity forward is positive z.
                // (https://docs.unity3d.com/ScriptReference/Camera-cameraToWorldMatrix.html)
                float3 viewVector = mul(unity_CameraInvProjection, float4(input.uv * 2 - 1, 0, -1));
                output.viewVector = mul(unity_CameraToWorld, float4(viewVector, 0));

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                // half4 var_UVTex = SAMPLE_TEXTURE2D(_UVTex, sampler_UVTex, input.uv);
                // return var_UVTex;
                // return float4(input.uv, 0, 1);
                // return _InverseProjectionMatrix;

                float nonlin_depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.uv);
                // return depth;
                float depth = LinearEyeDepth(nonlin_depth, _ZBufferParams);
                // return linearDepth;
                float4 worldPos = GetWorldSpacePosition(nonlin_depth, input.uv);
                // return worldPos;
                float3 rayPos = _WorldSpaceCameraPos;
                float viewLength = length(input.viewVector);
                float3 rayDir = input.viewVector / viewLength;
                //相机到每个像素的世界方向
                float3 worldViewDir = normalize(worldPos.xyz - rayPos.xyz);
                return float4(worldViewDir, 1);
                return var_MainTex * 3 ;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
