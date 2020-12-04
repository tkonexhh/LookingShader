Shader "XHH/Rust"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
        _SpecularPow ("SpecularPos", Range(0.1, 100)) = 1
        _SpecularStrength ("SpecularStrength", Range(0, 10)) = 1
        _MainCol ("MainCol", Color) = (1, 1, 1, 1)
        _RustCol ("RustCol", Color) = (0, 0, 0, 1)
        _RustLerpCol ("RustLerpCol", Color) = (0, 0, 0, 1)
        _RustWidth ("RustWidth", Range(0, 0.1)) = 0.01
        _NoiseTex ("NoiseTex", 2D) = "Gery" { }
        _RustStrength ("RustStrength", Range(0, 1)) = 0.5
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
            float _SpecularPow, _SpecularStrength, _RustStrength, _RustWidth;
            float4 _MainCol, _RustCol, _RustLerpCol;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };


            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 positionWS: TEXCOORD1;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.positionWS = TransformObjectToWorld(input.normalOS.xyz);
                output.uv = input.uv;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                Light myLight = GetMainLight();
                float3 lightDir = normalize(myLight.direction);
                float4 lightCol = float4(myLight.color, 1);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS) ;
                
                float ldotn = dot(lightDir, input.normalWS);
                float lambert = saturate(ldotn);

                
                

                //Blinn-Phong
                // float3 halfDir = normalize(viewDir + lightDir);
                // float hdotn = saturate(dot(halfDir, input.normalWS));
                float3 reflectDir = normalize((reflect(-lightDir, input.normalWS)));
                //specular
                float rdotn = saturate(dot(reflectDir, input.normalWS));
                float specular = pow(rdotn, _SpecularPow) * _SpecularStrength;
                float4 specularCol = specular * lightCol;

                float4 diffuseCol = lambert * lightCol * _MainCol;
                float4 MainCol = diffuseCol + specularCol;
                half4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);

                half4 noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv * 5);
                half stepNoise = step(noiseTex.r, _RustStrength - _RustWidth);
                half stepNoise2 = step(noiseTex.r, _RustStrength);
                
                float4 rustLerpCol = _RustLerpCol * lambert * lightCol;
                float4 rustCol = (stepNoise * _RustCol + (stepNoise2 - stepNoise) * _RustLerpCol) * lambert * lightCol;
                float4 finalCol = lerp(MainCol, rustCol, stepNoise2);

                

                return finalCol;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
