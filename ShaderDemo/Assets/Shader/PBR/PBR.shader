
Shader "XHH/PBR"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_BaseMap ("BaseMap", 2D) = "white" { }
        _Glossiness ("Glossiness", Range(0, 1)) = 0.5//光泽度 粗糙度
        
        [Toggle(_METALLICSPECGLOSSMAP)]_METALLICSPECGLOSSMAP ("开启MetallicGlossMap", int) = 1
        _Metallic ("Metallic", Range(0, 1)) = 0.5//金属度
        [NoScaleOffset]_MetallicGlossMap ("Metallic", 2D) = "white" { }

        [NoScaleOffset]_MaskMap ("MaskMap R:金属度 G:光泽度 B:AO A:", 2D) = "white" { }

        [NoScaleOffset][Normal]_BumpMap ("NormalMap", 2D) = "bump" { }
        _BumpScale ("NormalScale", Range(0, 2)) = 1

        // [Toggle(_EMISSION)]_EMISSION ("开启EMISSION", int) = 1
        // _EmissionColor ("Emission Color", Color) = (0, 0, 0)
        // [NoScaleOffset]_EmissionMap ("Emission", 2D) = "white" { }
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
            // #pragma shader_feature _OCCLUSIONMAP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../CustomHlsl/CustomLighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            // float4 _EmissionColor;
            float _Glossiness, _Metallic, _BumpScale;

            CBUFFER_END

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            TEXTURE2D(_MetallicGlossMap);
            // TEXTURE2D(_EmissionMap);

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
                float3 tangentWS: TEXCOORD3;
                float3 bitangentWS: TEXCOORD4;
            };
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.uv;
                output.normalWS = normalize(TransformObjectToWorldNormal(input.normalOS, true));
                output.tangentWS = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));
                output.bitangentWS = normalize(cross(output.normalWS, output.tangentWS) * input.tangentOS.w);
                
                return output;
            }

            float D_Function(float NdotH, float roughness)
            {
                float a2 = roughness * roughness;
                float NdotH2 = NdotH * NdotH;

                float denom = NdotH2 * (a2 - 1) + 1;
                denom = denom * denom * 3.1415926535;
                return a2 / denom;
            }

            float G_Function(float NdotL, float NdotV, float roughness)
            {
                float a1 = NdotL / lerp(NdotL, 1, roughness);
                float a2 = NdotV / lerp(NdotV, 1, roughness);
                return a1 * a2;
            }

            float3 F_Function(float HdotL, float3 F0)
            {
                float fre = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
                return lerp(fre, 1, F0);
            }

            //F项 间接光
            real3 IndirF_Function(float NdotV, float3 F0, float roughness)
            {
                float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
                return F0 + Fre * saturate(1 - roughness - F0);
            }

            //间接光漫反射 球谐函数 光照探针
            real3 SH_IndirectionDiff(float3 normalWS)
            {
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
                float3 Color = SampleSH9(SHCoefficients, normalWS);
                return max(0, Color);
            }

            //间接光高光 反射探针
            real3 IndirSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
            {
                float3 reflectDirWS = reflect(-viewWS, normalWS);
                roughness = roughness * (1.7 - 0.7 * roughness);//Unity内部不是线性 调整下拟合曲线求近似
                float MidLevel = roughness * 6;//把粗糙度remap到0-6 7个阶级 然后进行lod采样
                float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//根据不同的等级进行采样
                #if !defined(UNITY_USE_NATIVE_HDR)
                    return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
                #else
                    return speColor.xyz * AO;
                #endif
            }

            //间接高光 曲线拟合 放弃LUT采样而使用曲线拟合
            real3 IndirSpeFactor(float roughness, float smoothness, float3 BRDFspe, float3 F0, float NdotV)
            {
                #ifdef UNITY_COLORSPACE_GAMMA
                    float SurReduction = 1 - 0.28 * roughness, roughness;
                #else
                    float SurReduction = 1 / (roughness * roughness + 1);
                #endif
                #if defined(SHADER_API_GLES)//Lighting.hlsl 261行
                    float Reflectivity = BRDFspe.x;
                #else
                    float Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
                #endif
                half GrazingTSection = saturate(Reflectivity + smoothness);
                float Fre = Pow4(1 - NdotV);//lighting.hlsl第501行
                //float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);//lighting.hlsl第501行 它是4次方 我是5次方
                return lerp(F0, GrazingTSection, Fre) * SurReduction;
            }


            float4 frag(Varyings input): SV_Target
            {
                //向量准备
                float4 var_NormalTex = SAMPLE_TEXTURE2D(_BumpMap, sampler_BaseMap, input.uv);
                float3 normalTS = UnpackNormalScale(var_NormalTex, _BumpScale) ;
                // normalTS.z = sqrt(1 - saturate(dot(normalTS.xy, normalTS.xy)));
                float3x3 TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = normalize(mul(normalTS, TBN));
                
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
                float Metallic = _Metallic;
                float AO = 1;
                #if _METALLICSPECGLOSSMAP
                    float4 var_MetallicTex = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_BaseMap, input.uv);
                    Metallic = var_MetallicTex.r;
                #endif
                //粗糙度
                float roughness = 1 - _Glossiness;
                roughness = roughness * roughness;
                float3 F0 = lerp(0.04, Albedo, Metallic);
                // return float4(F0 * Opacity, Opacity);
                
                //法线分布函数
                // float D = D_Function(roughness, NdotH);
                float D = GGXNDF(roughness, NdotH);

                //几何阴影函数
                // float G = G_Function(NdotL, NdotV, roughness);
                float G = GGXGSF(NdotL, NdotV, roughness);
                // return G;

                //Fresnal
                float3 F = F_Function(NdotL, F0);
                // return float4(F, 1);
                
                //直接光高光
                float3 baseColor = var_BaseTex.rgb * _BaseColor.rgb;
                float3 BRDF = D * G * F / (4 * NdotL * NdotV);
                float3 DirectSpeColor = BRDF * lightCol * NdotL * PI;
                // return float4(DirectSpeColor, Opacity);

                //直接光漫反射
                float3 KS = F;
                float3 KD = (1 - KS) * (1 - Metallic);
                float3 DirectDiffColor = KD * Albedo * lightCol * NdotL;
                // return float4(DirectDiffColor, Opacity);

                float3 DirectColor = DirectSpeColor + DirectDiffColor;
                // return float4(DirectColor, Opacity);

                //间接光部分
                //光照探针 漫反射
                float3 SHcolor = SH_IndirectionDiff(normalWS) * AO;
                float3 IndirKS = IndirF_Function(NdotV, F0, roughness);
                float3 IndirKD = (1 - IndirKS) * (1 - Metallic);
                float3 InDirectDiffColor = SHcolor * IndirKD * Albedo;
                // return float4(InDirectDiffColor, 1);

                //高光反射 镜面反射IBL
                float3 IndirSpeCubeColor = IndirSpeCube(normalWS, viewDirWS, roughness, AO);
                // return float4(IndirSpeCubeColor, 1);
                float3 IndirSpeCubeFactor = IndirSpeFactor(roughness, _Glossiness, BRDF, F0, NdotV);
                // return float4(IndirSpeCubeFactor, 1);
                float3 IndirSpeColor = IndirSpeCubeColor * IndirSpeCubeFactor;
                // return float4(IndirSpeColor, 1);
                float3 InDirectColor = IndirSpeColor + InDirectDiffColor;
                // return float4(IndirColor, 1);

                float3 Color = InDirectColor + DirectColor;

                #if _EMISSION
                    
                #endif

                return float4(Color, Opacity);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
