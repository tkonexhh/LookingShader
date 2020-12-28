Shader "Xhh/Matcap"
{
    Properties
    {
        _MatcapTex ("MatcapTex", 2D) = "White" { }
        _NormalMap ("NomalMap", 2D) = "bump" { }
        _FresnelPos ("FresnelPow", Range(1, 10)) = 1
        _EvnLigntStrength ("EvnLigntStrength", Range(0, 5)) = 1
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "../../CustomHlsl/CustomHlsl.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float _FresnelPos, _EvnLigntStrength;

            CBUFFER_END

            TEXTURE2D(_MatcapTex);SAMPLER(sampler_MatcapTex);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
                float4 tangentOS: TANGENT;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD1;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 tangentWS: TEXCOORD2;
                float3 bitangentWS: TEXCOORD3;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.tangentWS = TransformObjectToWorld(input.tangentOS.xyz);
                output.bitangentWS = normalize(cross(output.normalWS, output.tangentWS) * input.tangentOS.w);
                output.uv = input.uv;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                //准备向量
                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
                float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                //mul(UNITY_MATRIX_V, float4(nDirWS, 1)).xyz;//
                float3 nDirVS = TransformWorldToView(nDirWS);//将normal从WS转到VS
                float3 vDirWS = normalize(_WorldSpaceCameraPos - input.positionWS);
                // float3 vrDirWS = reflect(-vDirWS, nDirWS);

                // Light light = GetMainLight();
                // float3 lightDir = light.direction;
                // float3 lightCol = light.color;

                float2 matcapUV = remap(nDirVS.rg, -1, 1, 0, 1);//nDirVS.rg * 0.5 + 0.5
                float ndotv = dot(nDirWS, vDirWS);


                float3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, sampler_MatcapTex, matcapUV);
                float fresnel = pow(1 - ndotv, _FresnelPos);
                float3 envSpecLighting = matcap * fresnel * _EvnLigntStrength;
                float4 finalCol = float4(matcap, 1);
                return finalCol;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
