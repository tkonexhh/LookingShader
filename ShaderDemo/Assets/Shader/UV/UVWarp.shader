Shader "XHH/UVWarp"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
        _NoiseTex ("NoiseTex", 2D) = "black" { }
        _MoveSpeed ("MoveSpeed", vector) = (1, 1, 0, 0)
        _WarpStrength ("WarpStrength", Range(0, 5)) = 1
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

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);float4 _MainTex_ST;
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);float4 _NoiseTex_ST;

            float2 _MoveSpeed;
            float _WarpStrength;
            
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
                float2 uv1: TEXCOORD1;
                float3 normalWS: NORMAL;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;
                output.uv = output.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                output.uv1 = input.uv + frac(_Time.x * _MoveSpeed);
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half2 var_Noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv1);
                half2 uvBias = (var_Noise - 0.5) * _WarpStrength;
                float2 newUV = input.uv + uvBias;
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, newUV);
                return tex;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
