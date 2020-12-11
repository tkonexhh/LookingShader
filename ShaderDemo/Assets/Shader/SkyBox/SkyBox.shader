Shader "XHH/SkyBox"
{
    Properties
    {
        [Header(Day)]
        _DayTopCol ("DayTopCol", Color) = (1, 1, 1, 1)
        _DayBottomCol ("DayBottomCol", Color) = (1, 1, 1, 1)
        _SunRadius ("SunRadius", Range(1, 100)) = 0.5
        [HDR]_SunCol ("SunCol", Color) = (1, 1, 1, 1)
        [Header(Night)]
        _NightTopCol ("NightTopCol", Color) = (1, 1, 1, 1)
        _NightBottomCol ("NightBottomCol", Color) = (1, 1, 1, 1)
        _MoonOffset ("MoonOffset 月亮正对太阳的偏移坐标", vector) = (0, 0, 0, 0)
        _MoonRadius ("MoonRadius", Range(1, 100)) = 0.5
        _MoonCol ("MoonCol", Color) = (1, 1, 1, 1)
        _MoonWaneCol ("MoonWaneCol", Color) = (0.1, 0.1, 0.1, 1)
        _MoonWane ("MoonWane 月亏方向 xyz 方向 z 缩放", vector) = (0, 0, 0, 1)


        [Header(Cloud)]
        _WindVec ("_WindVec XY方向以及速度", vector) = (1, 1, 0, 0)
        _CloudTex ("CloudTex", 2D) = "white" { }
        _CloudDistortTex ("CloudDistortTex", 2D) = "white" { }
        _CloudNoiseTex ("CloudNoiseTex", 2D) = "white" { }
        _CloudCutoff ("CloudCutoff", Range(0, 1)) = 1
        _CloudFuzziness ("CloudFuzziness", Range(0, 1)) = 1
        _CloudCol ("CloudCol", Color) = (1, 1, 1, 1)
        _CloudNigtCol ("CloudNightCol", Color) = (0.2, 0.2, 0.2, 1)

        [Header(Fog)]
        _FogHeight ("FogHeight", Range(0, 100)) = 1
    }
    SubShader
    {
        
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Background" "Queue" = "Background" "PreviewType" = "Skybox" }

        Pass
        {
            
            Cull Back
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../../CustomHlsl/CustomHlsl.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _DayTopCol, _DayBottomCol, _NightTopCol, _NightBottomCol, _SunCol, _MoonCol, _MoonWaneCol, _MoonWane, _CloudCol, _CloudNigtCol;
            float3 _MoonOffset;
            float2 _WindVec;
            float _SunRadius, _MoonRadius, _WindSpeed, _FogHeight, _CloudCutoff, _CloudFuzziness;
            CBUFFER_END

            TEXTURE2D(_CloudTex);SAMPLER(sampler_CloudTex);float4 _CloudTex_ST;
            TEXTURE2D(_CloudDistortTex);SAMPLER(sampler_CloudDistortTex);float4 _CloudDistortTex_ST;
            TEXTURE2D(_CloudNoiseTex);SAMPLER(sampler_CloudNoiseTex);float4 _CloudNoiseTex_ST;
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                // float3 normalOS: NORMAL;
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
                // output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                
                output.uv = input.uv;
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                //数据准备
                float3 nomalPosWS = normalize(input.positionWS);
                float _atan2 = atan2(nomalPosWS.x, nomalPosWS.z);
                _atan2 = _atan2 / (PI * 2) ;
                float _asin = asin(nomalPosWS.y) / (PI / 2);
                float2 uv = float2(_atan2, _asin);
                // return ceil(uv.y);
                float clampuv = remap(uv.y, -1, 1, 0, 1);
                
                
                Light light = GetMainLight();
                float3 lDirWS = light.direction;
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                

                //其实就是一个phong
                float vdotl = dot(lDirWS, vDirWS) ;
                float sun = pow(saturate(-vdotl), _SunRadius);//0.037
                float step_sun = round(sun);
                float3 sunCol = step_sun * _SunCol;

                float vdotlMoon = dot(normalize(lDirWS + _MoonOffset.xyz), vDirWS) ;
                float moon = pow(saturate(vdotlMoon), _MoonRadius);
                float step_moon = round(moon);
                // float3 moonCol = step_moon * _MoonCol;

                //处理月亏 对光的方向进行一定偏转
                float vdotlMoonMask = dot(normalize(lDirWS + _MoonOffset.xyz + _MoonWane.xyz), vDirWS) ;
                float moonMask = pow(saturate(vdotlMoonMask), _MoonRadius / _MoonWane.w);
                float step_moonMask = round(moonMask);

                //剩下的月亮区域
                float step_FinalMoon = saturate(step_moon - step_moonMask);
                //被挡住的区域
                float step_HideMoon = saturate(step_moon - step_FinalMoon);
                // return step_HideMoon;
                float3 moonCol = step_FinalMoon * _MoonCol + step_HideMoon * _MoonWaneCol;
                // return float4(moonCol, 1);
                
                float3 gradientDay = lerp(_DayBottomCol, _DayTopCol, clampuv);
                float3 gradientNight = lerp(_NightBottomCol, _NightTopCol, clampuv);
                float3 skyGradient = lerp(gradientDay, gradientNight, -lDirWS.y);

                float sunMoonMask = 1 - step_sun - step_moon;
                

                //处理cloud
                float scrollSpeed = _WindVec * _Time.x;
                float2 skyUV = input.positionWS.xz / input.positionWS.y;
                float2 skyBaseUV = skyUV * _CloudTex_ST.xy + _CloudTex_ST.zw;
                float4 skyBase = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, skyBaseUV + scrollSpeed) * ceil(uv.y);
                float2 noise1UV = skyUV * _CloudDistortTex_ST.xy + _CloudDistortTex_ST.zw;
                float noise1 = SAMPLE_TEXTURE2D(_CloudDistortTex, sampler_CloudDistortTex, noise1UV + scrollSpeed) * ceil(uv.y);
                float2 noise2UV = skyUV * _CloudNoiseTex_ST.xy + _CloudNoiseTex_ST.zw;
                float noise2 = SAMPLE_TEXTURE2D(_CloudNoiseTex, sampler_CloudNoiseTex, noise2UV + scrollSpeed) * ceil(uv.y);
                float4 finalNoise = skyBase * noise1 * noise2;
                float clouds = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _CloudFuzziness, finalNoise));
                float cloudCol = lerp(_CloudNigtCol, _CloudCol, lDirWS.y);


                float3 finalSkyCol = skyGradient * (1 - clouds) * sunMoonMask;
                float3 finalCloudCol = cloudCol * clouds ;
                
                float3 finalSunMoon = (moonCol + sunCol) ;
                float3 finalRGB = finalSkyCol + finalCloudCol + finalSunMoon * (1 - clouds);//moonCol + sunCol;//skyGradient;//

                //处理星空

                //处理地平线融合
                // float fog = pow(saturate(1 - input.uv.y), _FogHeight);
                // return fog * _SunCol;

                return float4(finalRGB, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
