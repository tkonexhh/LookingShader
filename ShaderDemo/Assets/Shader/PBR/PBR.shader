
Shader "XHH/PBR"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_BaseMap ("BaseMap", 2D) = "White" { }
        _Glossiness ("Glossiness", Range(0, 1)) = 0.5//光泽度 粗糙度
        
        [Toggle(_METALLICSPECGLOSSMAP)]_METALLICSPECGLOSSMAP ("开启MetallicGlossMap", int) = 1
        _Metallic ("Metallic", Range(0, 1)) = 0.5//金属度
        _MetallicGlossMap ("Metallic", 2D) = "white" { }

        // [Toggle(_NORMALMAP)]_NORMALMAP ("开启NormalMap", int) = 1
        [NoScaleOffset][Normal]_BumpMap ("NormalMap", 2D) = "bump" { }
        _BumpScale ("NormalScale", Range(0, 10)) = 1


        // [Toggle(_OCCLUSIONMAP)]_OCCLUSIONMAP ("开启OCCLUSIONMAP", int) = 1
        // _OcclusionStrength ("OcclusionStrength", Range(0.0, 1.0)) = 1.0
        // [NoScaleOffset]_OcclusionMap ("OcclusionMap", 2D) = "White" { }

        // [Toggle(_EMISSION)]_EMISSION ("开启EMISSION", int) = 1
        // _EmissionColor ("EmissionColor", Color) = (0, 0, 0)
        // [NoScaleOffset]_EmissionMap ("EmissionMap", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "IgnoreProjector" = "True" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Off
            // Blend One OneMinusSrcAlpha
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            // #pragma shader_feature _NORMALMAP
            // #pragma shader_feature _OCCLUSIONMAP
            // #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../CustomHlsl/CustomLighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float _Glossiness, _Metallic, _BumpScale;

            CBUFFER_END

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            TEXTURE2D(_MetallicGlossMap);

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
                float3 positionWS: TEXCOORD5;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                // #ifdef _NORMALMAP
                float3 tangentWS: TEXCOORD3;
                float3 bitangentWS: TEXCOORD4;
                // #endif
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS, true));
                // #ifdef _NORMALMAP
                output.tangentWS = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));
                output.bitangentWS = normalize(cross(output.normalWS, output.tangentWS) * input.tangentOS.w);
                // #endif
                return output;
            }

            float3 F_Function(float HdotL, float3 F0)
            {
                float fre = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
                return lerp(fre, 1, F0);
            }

            float4 frag(Varyings input): SV_Target
            {
                
                //向量准备
                // float3 normalWS;
                // #ifdef _NORMALMAP
                float4 var_NormalTex = SAMPLE_TEXTURE2D(_BumpMap, sampler_BaseMap, input.uv);
                float3 normalTS = UnpackNormal(var_NormalTex) ;
                // normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
                float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = normalize(mul(normalTS, TBN));
                // #else
                //     normalWS = input.normalWS;
                // #endif
                
                Light light = GetMainLight();
                float3 lightCol = light.color;
                float3 lightDirWS = light.direction;//光源方向
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);//视线到点的方向
                float3 viewReflectDirWS = normalize(reflect(-viewDirWS, normalWS));
                float3 halfDirWS = normalize(viewDirWS + lightDirWS);

                //中间变量
                float NdotL = max(saturate(dot(normalWS, lightDirWS)), 0.000001);
                float NdotV = max(saturate(dot(normalWS, viewDirWS)), 0.000001);
                float VRdotV = max(saturate(dot(viewReflectDirWS, viewDirWS)), 0.000001);
                float NdotH = max(saturate(dot(normalWS, halfDirWS)), 0.000001);
                float LdotH = max(saturate(dot(lightDirWS, halfDirWS)), 0.000001);
                float LdotV = max(saturate(dot(lightDirWS, viewDirWS)), 0.000001);
                float VdotH = max(saturate(dot(viewDirWS, halfDirWS)), 0.000001);
                
                //采样贴图
                float4 var_BaseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float3 Albedo = var_BaseTex.rgb * _BaseColor.rgb;
                float Opacity = var_BaseTex.a;
                //粗糙度
                float roughness = 1 - _Glossiness * _Glossiness;
                float3 F0 = lerp(1, Albedo * (1 - _Metallic), _Metallic);
                // return float4(F0 * Opacity, Opacity);
                // roughness = roughness * roughness;
                
                
                //高光
                float D = GGXNDF(roughness, NdotH);
                float G = GGXGSF(NdotL, NdotV, roughness);
                float3 F = SchlickFresnelFunction(F0, LdotH);
                //SphericalGaussianFresnelFunction(LdotH, 1);
                //F_Function(LdotH, F0);
                // return float4(F, 1);
                
                
                float3 baseColor = var_BaseTex.rgb * _BaseColor.rgb;
                float3 BRDF = D * G * F / (4 * NdotL * NdotV);
                float3 directColor = BRDF * lightCol * NdotL * PI / 2 ;
                return float4(directColor * Opacity * Albedo, Opacity);
                // *

                float3 diffColor = var_BaseTex.rgb * _BaseColor.rgb * (1.0 - _Metallic);
                float3 specColor = lerp(BRDF * NdotL, diffColor, _Metallic);
                return float4(specColor, 1);
                float3 finalRGB = BRDF * NdotL;
                #ifdef _METALLICSPECGLOSSMAP
                    float metallic = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_BaseMap, input.uv).r;
                    finalRGB *= (1 - metallic);
                #else
                    finalRGB *= (1 - _Metallic);
                #endif
                
                return float4(finalRGB, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
