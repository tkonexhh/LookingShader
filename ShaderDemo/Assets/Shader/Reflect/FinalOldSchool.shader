Shader "XHH/FinalOldSchool"
{
    Properties
    {
        [Header(Texture)]
        [NoScaleOffset] _MainTex ("MainTex RGB:颜色 A:AO", 2D) = "White" { }
        [NoScaleOffset] _NormalTex ("NormalTex", 2D) = "bump" { }
        [NoScaleOffset] _SpecTex ("高光贴图", 2D) = "grey" { }
        [NoScaleOffset] _EmmisionTex ("自发光贴图", 2D) = "White" { }
        [NoScaleOffset] _Cubemap ("环境贴图", Cube) = "_Skybox" { }
        
        [Header(Diffuse)]
        _MainCol ("基本色", Color) = (0.5, 0.5, 0.5, 1.0)
        _EnvStrength ("环境光强度", Range(0, 1)) = 0.2
        _EnvUpCol ("环境天顶颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _EnvSideCol ("环境水平颜色", Color) = (0.5, 0.5, 0.5, 1)
        _EnvDownCol ("环境地表颜色", Color) = (0.0, 0.0, 0.0, 1.0)
        [Header(Specular)]
        _SpecularPow ("高光次幂", Range(1, 90)) = 1
        _CubemapMip ("Cubmap Mip", Range(0, 7)) = 1
        _FresnelPow ("菲涅尔次幂", Range(0, 5)) = 1
        [Header(Emmision)]
        _EmmisionStrength ("自发光强度", Range(0, 10)) = 1
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
            float4 _MainCol, _EnvUpCol, _EnvSideCol, _EnvDownCol;
            float _EnvStrength, _SpecularPow, _CubemapMip, _FresnelPow, _EmmisionStrength;

            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURE2D(_SpecTex);SAMPLER(sampler_SpecTex);
            TEXTURECUBE(_Cubemap);SAMPLER(sampler_Cubemap);
            TEXTURE2D(_EmmisionTex);SAMPLER(sampler_EmmisionTex);
            
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
                output.uv = input.uv;
                output.tangentWS = TransformObjectToWorld(input.tangentOS);
                output.bitangentWS = normalize(cross(output.normalWS, output.tangentWS) * input.tangentOS.w);

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                
                
                
                //向量准备
                float4 var_NormalTex = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, input.uv);
                float3 normalTS = UnpackNormal(var_NormalTex);
                float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = normalize(mul(normalTS, TBN));

                Light light = GetMainLight();
                float3 lCol = light.color;
                float3 lDirWS = light.direction;
                float3 lRDirWS = reflect(-lDirWS, normalWS);
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 vrDirWS = normalize(reflect(-vDirWS, normalWS));//view 反射方向

                
                //中间向量
                float ndotl = dot(normalWS, lDirWS);
                float vdotlR = dot(lRDirWS, vDirWS);
                float vdotn = dot(vDirWS, normalWS);
                
                //贴图采样
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float4 var_SpecTex = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, input.uv);
                float cubeMip = lerp(_CubemapMip, 1.0, var_SpecTex.a);
                float3 var_Cubemap = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, vrDirWS, cubeMip);
                float4 var_EmmisionTex = SAMPLE_TEXTURE2D(_EmmisionTex, sampler_EmmisionTex, input.uv);

                float ao = var_MainTex.a;
                //光照模型
                float3 baseCol = var_MainTex.rgb * _MainCol;
                
                //光源漫反射
                float lambert = saturate(ndotl);
                
                //光源镜面反射
                float3 specCol = var_SpecTex.rgb;
                float3 specPow = lerp(1, _SpecularPow, var_SpecTex.a);
                float phong = pow(saturate(vdotlR), specPow);
                
                
                //光源反射混合

                float3 directLighting = (baseCol * lambert + specCol * phong) * lCol;

                //环境光漫反射
                float3 upMask = saturate(normalWS.y);
                float3 downMask = saturate(-normalWS.y);
                float3 sideMask = 1 - upMask - downMask;
                float3 upEnvCol = upMask * _EnvUpCol;
                float3 downEnvCol = downMask * _EnvDownCol;
                float3 sideEnvCol = sideMask * _EnvSideCol;
                float3 envCol = upEnvCol + downEnvCol + sideEnvCol;

                float3 envDiff = baseCol * envCol;
                //环境镜面反射
                float fresnel = pow(saturate(1 - vdotn), _FresnelPow);
                float3 envSpec = var_Cubemap * fresnel * _EnvStrength * var_SpecTex.a;
                //环境反射混合
                float occlusion = var_MainTex.a;
                float3 envLighting = (envDiff + envSpec) * occlusion;;


                //自发光
                float3 emmision = var_EmmisionTex.rgb * _EmmisionStrength ;
                

                float3 finalCol = directLighting + envLighting + emmision;
                
                return float4(finalCol, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
