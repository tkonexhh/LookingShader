Shader "XHH/Sequeue"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
        _Row ("行数", int) = 3
        _Cow ("列数", int) = 4
        _Speed ("Speed", float) = 1
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
            float _Row, _Cow;
            float _Speed;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            
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
                
                float squence = floor(_Time.y * _Speed);
                float y = floor(squence / _Cow);
                float x = floor(squence - y * _Row);
                
                half2 uv = input.uv + half2(x, -y + _Cow - 1);
                uv.x /= _Cow;
                uv.y /= _Row;
                output.uv = uv;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return var_MainTex;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
