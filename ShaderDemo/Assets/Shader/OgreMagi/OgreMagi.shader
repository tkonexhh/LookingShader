Shader "XHH/DOTA2/OgreMagi"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("MainTex RGB:颜色 A:透明", 2D) = "white" { }
        [Normal] _NormalTex ("法线贴图", 2D) = "bump" { }
        _SpecularTex ("高光贴图RGB:   A:高光Pow", 2D) = "black" { }
        _MaskTex ("高光遮罩贴图", 2D) = "black" { }
        _EmmisionTex ("自发光贴图", 2D) = "black" { }
        _CubemapTex ("环境贴图", Cube) = "_skybox" { }

        _DiffuseRampTex ("阴影RampTex", 2D) = "white" { }
        _FresnelRampTex ("菲涅尔RampTex", 2D) = "white" { }

        [Header(Value)]
        _SpecularStrength ("高光强度", Range(0, 3)) = 0.3
        _SpecularPow ("高光次幂", Range(1, 200)) = 1
        _FresnelPow ("菲涅尔次幂", Range(0, 15)) = 1
        _CubemapMip ("环境贴图Mip", Range(0, 7)) = 1
        _EnvStrength ("环境光强度", Range(0, 2)) = 1
        _EmmisionStrength ("自发光强度", Range(0, 2)) = 1
    }
    SubShader
    {
        
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float _SpecularPow, _SpecularStrength, _FresnelPow, _EmmisionStrength, _CubemapMip, _EnvStrength;

            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex);SAMPLER(sampler_NormalTex);
            TEXTURE2D(_SpecularTex);SAMPLER(sampler_SpecularTex);
            TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);
            TEXTURE2D(_EmmisionTex);SAMPLER(sampler_EmmisionTex);
            TEXTURE2D(_DiffuseRampTex);SAMPLER(sampler_DiffuseRampTex);
            TEXTURE2D(_FresnelRampTex);SAMPLER(sampler_FresnelRampTex);
            TEXTURECUBE(_CubemapTex);SAMPLER(sampler_CubemapTex);
            
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
                //

                //向量准备
                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, input.uv));
                float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));//法线方向

                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 vrDirWS = reflect(-vDirWS, nDirWS);
                
                Light light = GetMainLight();
                float3 lDirWS = light.direction;
                float3 lCol = light.color;

                float3 lRDirWS = reflect(-lDirWS, nDirWS);

                //中间量准备
                float ndotl = dot(nDirWS, lDirWS);
                float vdotlr = dot(vDirWS, lRDirWS);
                float vdotn = dot(vDirWS, nDirWS);

                //贴图采样
                float4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float4 var_EmmisionTex = SAMPLE_TEXTURE2D(_EmmisionTex, sampler_EmmisionTex, input.uv);
                
                float3 basicCol = var_MainTex.rgb;
                
                //光照模型
                //光源光照
                //光源漫反射
                float lambert = ndotl * 0.5 + 0.5;
                float3 var_DiffuseRampTex = SAMPLE_TEXTURE2D(_DiffuseRampTex, sampler_DiffuseRampTex, float2(lambert, 0));
                float3 diffuse = basicCol * var_DiffuseRampTex;
                //光源镜面反射
                float4 var_SpecularTex = SAMPLE_TEXTURE2D(_SpecularTex, sampler_SpecularTex, input.uv);
                // return float4(var_SpecularTex.rgb, var_MainTex.a);
                
                // float specularPow = _SpecularBase * _SpecularPow * var_SpecularTex.a;
                // return float4(var_SpecularTex.a, var_SpecularTex.a, var_SpecularTex.a, var_MainTex.a);
                float specularPow = lerp(1, _SpecularPow, var_SpecularTex.a);
                float phong = pow(saturate(vdotlr), specularPow);

                float3 normalSpecular = phong * _SpecularStrength * var_SpecularTex.r;
                
                // return float4(normalSpecular, var_MainTex.a);
                float3 var_MaskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uv).rgb;
                float phongMetal = pow(saturate(vdotlr), specularPow / 1.2);
                float3 matealSpecular = phongMetal * _SpecularStrength * var_MaskTex ;
                // return float4(matealSpecular, var_MainTex.a);
                float3 specular = normalSpecular + matealSpecular;
                
                // return float4(specular, var_MainTex.a);
                //光源融合
                float3 lightingCol = (diffuse + specular) * lCol;

                //环境
                //环境光镜面反射
                float3 var_FresnalTex = SAMPLE_TEXTURE2D(_FresnelRampTex, sampler_FresnelRampTex, input.uv).rgb;
                float3 var_Cubemap = SAMPLE_TEXTURECUBE_LOD(_CubemapTex, sampler_CubemapTex, vrDirWS, _CubemapMip);
                // return float4(var_Cubemap, 1);
                float fresnel = pow(1 - vdotn, _FresnelPow) ;
                // return fresnel;
                float3 rimCol = fresnel * var_SpecularTex.g * var_FresnalTex;
                // return float4(rimCol, var_MainTex.a);
                

                //金属的下表面反射cubemap
                float3 downMask = nDirWS.y * var_MaskTex;
                float3 downMetalEnvSpec = var_Cubemap * downMask * _EnvStrength;
                
                //自发光
                float3 emmision = var_EmmisionTex.rgb * _EmmisionStrength * basicCol;

                float3 finalRGB = lightingCol + rimCol + emmision + downMetalEnvSpec;

                return float4(finalRGB, var_MainTex.a);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
