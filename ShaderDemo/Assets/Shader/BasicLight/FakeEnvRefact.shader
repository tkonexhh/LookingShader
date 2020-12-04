Shader "Unlit/FakeEnvRefact"
{
    Properties
    {
        _MainTex ("RampTex", 2D) = "White" { }
        _RampVal ("RampVal", Range(0, 1)) = 0
        _EnvVal ("EnvVal", Range(0, 1)) = 0
        _SpecularPow ("SpecularPow", Range(1, 100)) = 1
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../CustomHlsl/CustomHlsl.hlsl"
            
            CBUFFER_START(UnityPerMaterial)

            float _RampVal, _EnvVal, _SpecularPow;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                float3 normalOS: NORMAL;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float3 positionWS: TEXCOORD2;
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
                Light myLight = GetMainLight();
                float3 lightDir = normalize(myLight.direction.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                float3 reflectDir = reflect(viewDir, input.normalWS);
                float ldotv = dot(lightDir, reflectDir);
                
                float remapDot = remap(ldotv, -1, 1, 0, 1);

                float4 rampTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(remapDot, _RampVal)) * _EnvVal;

                float4 specular = pow(remapDot, _SpecularPow);

                float ldotn = dot(lightDir, input.normalWS);

                float4 finalCol = ldotn * rampTex + specular;

                return finalCol;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}