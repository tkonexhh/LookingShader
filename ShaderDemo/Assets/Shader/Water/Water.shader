Shader "XHH/Water"
{
    Properties
    {
        [Header(Base Color)]
        _ColorDark ("Color Dark", color) = (0, 0, 0, 1)
        _ColorLight ("Color Light", Color) = (0.235, 0.7547169, 0.745, 1)
        
        [Header(Base Wave)]
        _Wave1 ("Wave 1 (XY:Dir Z:Steepness(0-1) W:wavelength)", vector) = (1.0, 0.0, 0.5, 10)
        _Wave2 ("Wave 2", vector) = (0.0, 0.25, 0.25, 20)
        _Wave3 ("Wave 3", vector) = (1.0, 1.0, 0.15, 10)
        _Wave4 ("Wave 4", vector) = (1.0, 1.0, 0.15, 10)
        _WaterFogStength ("Water Fog Strength", Range(0, 10)) = 2
        _DepthOffset ("DepthOffset", Range(0, 100)) = 0.1

        [Header(Water Surface)]
        _FoamWidth ("Foam Width", float) = 5
        _FoamColor ("Foam Color", Color) = (1, 1, 1, 1)
        _FoamSpeed ("Foam Speed", float) = 10
        _FoamStep ("Foam Step", Range(0, 1)) = 0.1
        _WaterNoiseTex ("WaterNoiseTex", 2D) = "white" { }
        
        


        [Header(Refract)]//折射
        _RefractStrength ("RefractStrength", Range(0, 0.5)) = 0.2
        // [Normal]_WaterNormalTex ("WaterNormalTex", 2D) = "bump" { }
        // [Header(Reflect)]//反射
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            // Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float4 _Wave1, _Wave2, _Wave3, _Wave4;
            float _DepthOffset;
            float _WaterFogStength;
            float4 _ColorDark, _ColorLight;

            float _RefractStrength;
            float _FoamSpeed;
            float _FoamStep, _FoamWidth;
            float4 _FoamColor;
            CBUFFER_END
            TEXTURE2D(_WaterNoiseTex); SAMPLER(sampler_WaterNoiseTex);float4 _WaterNoiseTex_ST;
            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
            
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
                float4 positionSS: TEXCOORD2;//屏幕坐标
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                //float3 tangentWS: TEXCOORD3;
                //float3 bitangentWS: TEXCOORD4;
            };

            float3 GerstnerWava(float4 wave, float3 p, inout float3 tangent, inout float3 bitangent)
            {
                float steepness = wave.z;
                float length = wave.w;
                float2 waveDir = normalize(wave.xy);

                float k = 2 * PI / length;
                float speed = sqrt(9.8 / k);
                float f = k * (dot(waveDir, p.xz) - speed * _Time.y);
                float a = steepness / k;

                tangent += float3(
                    - waveDir.x * waveDir.x * (steepness * sin(f)),
                    waveDir.x * steepness * cos(f),
                    - waveDir.x * waveDir.y * steepness * sin(f)
                );

                bitangent += float3(
                    - waveDir.x * waveDir.y * steepness * sin(f),
                    waveDir.y * steepness * cos(f),
                    - waveDir.y * waveDir.y * steepness * sin(f)
                );

                return float3(
                    waveDir.x * a * cos(f),
                    a * sin(f),
                    waveDir.y * a * cos(f)
                );
            }

            float4 CalculateSSSColor(float3 lightDirection, float3 worldNormal, float3 viewDir, float waveHeight, float shadowFactor)
            {
                float lightStrength = sqrt(saturate(lightDirection.y));
                float SSSFactor = pow(saturate(dot(viewDir, lightDirection)) + saturate(dot(worldNormal, -lightDirection)), 0.1) * shadowFactor * lightStrength * 1;
                return _ColorLight * (SSSFactor + waveHeight * 0.6);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 tangent = float3(1, 0, 0);
                float3 bitangent = float3(0, 0, 1);
                input.positionOS.xyz += GerstnerWava(_Wave1, input.positionOS.xyz, tangent, bitangent);
                input.positionOS.xyz += GerstnerWava(_Wave2, input.positionOS.xyz, tangent, bitangent);
                input.positionOS.xyz += GerstnerWava(_Wave3, input.positionOS.xyz, tangent, bitangent);
                input.positionOS.xyz += GerstnerWava(_Wave4, input.positionOS.xyz, tangent, bitangent);
                float3 normal = normalize(cross(bitangent, tangent));
                input.normalOS = normal;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.positionSS = ComputeScreenPos(output.positionCS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                //output.tangentWS = TransformObjectToWorld(input.tangentOS.xyz);
                //output.bitangentWS = normalize(cross(output.tangentWS, output.normalWS) * input.tangentOS.w);
                output.uv = input.uv;


                return output;
            }

            
            float4 frag(Varyings input): SV_Target
            {
                Light light = GetMainLight();
                float3 lightDirWS = normalize(light.direction);
                // float3 normalWS = normalize(input.normalWS);
                float3 normalWS = normalize(cross(ddy(input.positionWS), ddx(input.positionWS)));
                // return float4(normalWS, 1);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float NdotL = saturate(dot(lightDirWS, normalWS));
                
                float2 screenUV = input.positionSS.xy / input.positionSS.w;//input.positionCS.xy / _ScreenParams.xy;
                float var_depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                float depth_Buffer = LinearEyeDepth(var_depth, _ZBufferParams);
                // return depth_Buffer / 500;
                
                float depthGap = depth_Buffer - input.positionSS.w;
                float depthLerp = saturate(depthGap / _DepthOffset);
                depthLerp = saturate(pow(depthLerp, _WaterFogStength));
                // return depthLerp;
                float4 waterColor = lerp(_ColorLight, _ColorDark, depthLerp);
                
                
                float3 finalRGB = NdotL * waterColor;
                float alpha = depthLerp;
                
                //折射refractive
                float2 refractUV = screenUV + input.normalWS.xz * _RefractStrength;
                half4 var_CameraTex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, refractUV);
                // return var_CameraTex;
                half3 lerpRefract = lerp(float3(0, 0, 0), var_CameraTex, 1 - alpha);
                // return float4(lerpRefract, 1);


                //水面
                float speed = _Time.x * _FoamSpeed;
                float2 uv_WaterNoise = input.uv * _WaterNoiseTex_ST.xy + _WaterNoiseTex_ST.zw + speed;
                float var_WaterNoise = SAMPLE_TEXTURE2D(_WaterNoiseTex, sampler_WaterNoiseTex, uv_WaterNoise).r;
                // return var_WaterNoise;
                
                float foamStep = saturate((depthGap / _FoamWidth)) * _FoamStep ;
                // return foamStep - var_WaterNoise > 0?1: 0; //> _FoamStep?0: 1;
                // return foamStep;
                float surfaceNoise = 1 - step(var_WaterNoise, foamStep);
                // return surfaceNoise;
                
                waterColor = lerp(float4(lerpRefract, 1), float4(lerpRefract + finalRGB, 1), alpha);
                // return waterColor;
                // return float4(finalRGB + waterSurface, 1);
                return waterColor + surfaceNoise;
                // return float4(finalRGB, alpha);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
