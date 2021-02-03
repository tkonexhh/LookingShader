Shader "XHH/Water"
{
    Properties
    {
        _ColorDark ("Color Dark", color) = (0, 0, 0, 1)
        _ColorLight ("Color Light", Color) = (1, 1, 1, 1)
        _EdgeColor ("EdgeColor", Color) = (1, 1, 1, 1)
        [Header(Base Wave)]
        _Wave1 ("Wave 1 (XY:Dir Z:Steepness(0-1) W:wavelength)", vector) = (1.0, 0.0, 0.5, 10)
        _Wave2 ("Wave 2", vector) = (0.0, 0.25, 0.25, 20)
        _Wave3 ("Wave 3", vector) = (1.0, 1.0, 0.15, 10)
        _Wave4 ("Wave 4", vector) = (1.0, 1.0, 0.15, 10)
        _DepthOffset ("DepthOffset", Range(1, 100)) = 0.1

        _Temp1 ("Temp1", float) = 1
        [Header(Refract)]//折射
        _RefractStrength ("RefractStrength", Range(0, 1)) = 0.2
        // [Header(Reflect)]//反射
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            // Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
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
            float4 _ColorDark, _ColorLight;
            float4 _EdgeColor;

            float _RefractStrength;

            float _Temp1;
            CBUFFER_END

            TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            TEXTURE2D(_CameraColorTexture);SAMPLER(sampler_CameraColorTexture);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float4 positionSS: TEXCOORD2;//屏幕坐标
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };

            float3 GerstnerWava(float4 wave, float3 p, inout float3 tangent, inout float3 bitangent)
            {
                float steepness = wave.z;
                float waveLength = wave.w;
                float2 waveDir = normalize(wave.xy);

                float k = 2 * PI / waveLength;
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
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionSS = ComputeScreenPos(output.positionCS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;


                return output;
            }

            
            float4 frag(Varyings input): SV_Target
            {
                Light light = GetMainLight();
                float3 lightDirWS = normalize(light.direction);
                float NdotL = saturate(dot(lightDirWS, input.normalWS));
                // return NdotL;
                float2 screenUV = input.positionSS.xy / input.positionSS.w;//input.positionCS.xy / _ScreenParams.xy;
                float var_depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV);
                float depth_Buffer = LinearEyeDepth(var_depth, _ZBufferParams);
                // return float4(var_depth, var_depth, var_depth, 1);
                // float depth = input.positionCS.z;
                // depth = LinearEyeDepth(depth, _ZBufferParams);
                
                float depthGap = depth_Buffer - input.positionSS.w;
                // return depthGap / 10;
                float depthLerp = saturate(depthGap / _DepthOffset);
                float4 waterColor = lerp(_ColorLight, _ColorDark, depthLerp);
                // return waterColor;
                // float edge = saturate((depth - depth_Buffer + _DepthOffset)) * 1000;
                // float edge2 = 1 - pow(saturate((depth - depth_Buffer + _DepthOffset)), _Temp1) ;
                // return edge ;
                float3 finalRGB = NdotL * waterColor;
                float alpha = depthLerp;
                
                
                //折射
                //refractive
                // float2 refractUV = screenUV + input.normalWS.xz * _RefractStrength;
                // half4 var_CameraTex = SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, refractUV);
                // finalRGB += (1 - depthLerp) * var_CameraTex.rgb;

                return float4(finalRGB, alpha);

                return NdotL;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
