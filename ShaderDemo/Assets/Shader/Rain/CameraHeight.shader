Shader "XHH/HeightCamera"
{
    Properties { }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "HeightCamera" }

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

            
            struct Attributes
            {
                float4 positionOS: POSITION;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float depth: TEXCOORD1;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.depth = TransformObjectToWorld(input.positionOS.xyz).y;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                //将255米的高度压缩到0-1写入r，每一米内的高度写入b，复原时r*255+b就是实际高度
                return float4(floor(input.depth) / 255, frac(input.depth), 1, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
