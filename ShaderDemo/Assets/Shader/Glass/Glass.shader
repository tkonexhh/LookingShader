Shader "XHH/Glass Geometry Shader"
{
    Properties
    {
        _GlassColor ("GlassColor", color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM
            
            #pragma target 2.0
            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _GlassColor;

            CBUFFER_END

            
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };

            struct GeomData
            {
                float4 positionCS: SV_POSITION;
                float3 normalWS: NORMAL;
                float2 uv: TEXCOORD0;
                float3 color: COLOR;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };


            
            GeomData vert(Attributes input)
            {
                GeomData output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;
                
                return output;
            }

            [maxvertexcount(3)]
            void geom(triangle GeomData IN[3], inout TriangleStream < GeomData > triStream)
            {
                GeomData vert0 = input[0];
                GeomData vert1 = input[1];
                GeomData vert2 = input[2];
                
                triStream.Append(vert0);
                triStream.Append(vert1);
                triStream.Append(vert2);
                triStream.RestartStrip();
            }

            float4 frag(Varyings input): SV_Target
            {
                
                return _GlassColor;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
