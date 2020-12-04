Shader "XHH/Ambient"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
        _UpAmbientCol ("UpAmbientCol", Color) = (1, 1, 1, 1)
        _DownAmbientCol ("DownAmbientCol", Color) = (1, 1, 1, 1)
        _SideAmbientCol ("SideAmbientCol", Color) = (1, 1, 1, 1)
        _SpecularPow ("SpecularPos", Range(1, 100)) = 1
        _OcclusionTex ("AoTex", 2D) = "White" { }
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
            float4 _UpAmbientCol, _DownAmbientCol, _SideAmbientCol;
            float _SpecularPow;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_OcclusionTex);SAMPLER(sampler_OcclusionTex);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float upMask = saturate(input.normalWS.y);
                float downMask = saturate(-input.normalWS.y);
                float sideMask = saturate(1 - upMask - downMask);

                float4 upCol = upMask * _UpAmbientCol;
                float4 downCol = downMask * _DownAmbientCol;
                float4 sideCol = sideMask * _SideAmbientCol;

                float4 ambientCol = downCol + upCol + sideCol;

                
                Light light = GetMainLight();
                float3 lightDir = normalize(light.direction);
                float4 lightCol = float4(light.color, 1);

                float lambert = saturate(dot(lightDir, input.normalWS));
                float4 lambertCol = lambert * lightCol;

                float3 refectDir = (normalize(reflect(-lightDir, input.normalWS)));
                float3 specular = pow(saturate(dot(refectDir, input.normalWS)), _SpecularPow);
                float4 specularCol = float4(specular, 1);

                
                float4 finalCol = ambientCol + lambertCol + specularCol ;

                return finalCol ;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
