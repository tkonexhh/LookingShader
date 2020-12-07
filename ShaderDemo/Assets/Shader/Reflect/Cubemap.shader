Shader "XHH/Cubemap"
{
    Properties
    {
        _CubeMap ("CubeMap", Cube) = "White" { }
        _MipLvl ("MipLvl", Range(0, 7)) = 0
        _FresnelPow ("FresnelPow", Range(0, 5)) = 1
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
            #include "../../CustomHlsl/CustomHlsl.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float _MipLvl, _FresnelPow;
            CBUFFER_END

            TEXTURECUBE(_CubeMap); SAMPLER(sampler_CubeMap);
            
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
                float3 normalDirWS = input.normalWS;
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - input.positionWS);
                float3 viewRDirWs = reflect(-viewDirWS, normalDirWS);
                float3 cub = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, viewRDirWs, _MipLvl);

                float ndotv = dot(normalDirWS, viewDirWS);
                float3 fresnel = pow(1 - ndotv, _FresnelPow);

                return float4(cub * fresnel, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
