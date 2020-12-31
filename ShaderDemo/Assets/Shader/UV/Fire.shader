
Shader "XHH/Fire"
{
    Properties
    {
        _Mask ("Mask R外焰 G B A ", 2D) = "Blue" { }
        _Noise ("Noise R:Noise1 G:Noise2", 2D) = "grey" { }
        _Noise1Params ("Noise1 X:tilling Y:speed Z:strength", vector) = (1, 1, 0.2, 0)
        _Noise2Params ("Noise2 X:tilling Y:speed Z:strength", vector) = (1, 1, 0.2, 0)
        [HDR]_Color1 ("Color1", Color) = (1, 1, 1, 1)
        [HDR]_Color2 ("Color2", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend One OneMinusSrcAlpha
            Cull Back
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float3 _Noise1Params;
            float3 _Noise2Params;

            float4 _Color1, _Color2;
            CBUFFER_END

            TEXTURE2D(_Mask);SAMPLER(sampler_Mask);
            TEXTURE2D(_Noise);SAMPLER(sampler_Noise);
            
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;//采样mask
                float2 uv1: TEXCOORD1;//采样noise1
                float2 uv2: TEXCOORD2;//采样noise1
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                output.uv1 = output.uv * _Noise1Params.x - float2(0, frac(_Time.x * _Noise1Params.y));
                output.uv2 = output.uv * _Noise2Params.x - float2(0, frac(_Time.x * _Noise2Params.y));

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                
                half var_Noise1Tex = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, input.uv1).r;
                half var_Noise2Tex = SAMPLE_TEXTURE2D(_Noise, sampler_Noise, input.uv2).g;
                
                half noise = var_Noise1Tex * _Noise1Params.z + var_Noise2Tex * _Noise2Params.z;

                float2 warpUV = input.uv - float2(0, noise);

                half4 var_MaskTex = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, warpUV);

                float3 finalRGB = var_MaskTex.r * _Color1 + var_MaskTex.g * _Color2;
                // return finalRGB.b;
                float opacity = var_MaskTex.r + var_MaskTex.g;
                // return var_MaskTex.r;
                return float4(finalRGB * opacity, opacity);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
