Shader "Unlit/RampTextLambert"
{
    Properties
    {
        _SSS ("SSS", Range(0, 1)) = 1
        [NoScaleOffset]_RampTexture ("RanpTexture", 2D) = "white"
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
            //------------
            //Unity defined keywords

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial);
            float _SSS;
            CBUFFER_END

            TEXTURE2D(_RampTexture);SAMPLER(sampler_RampTexture);


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
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };

            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;
                
                return output;
            }

            float4 frag(Varyings input): SV_Target
            {
                
                Light myLight = GetMainLight();
                float3 lightDir = normalize(myLight.direction);
                float3 normalDir = normalize(input.normalWS);
                float4 lightColor = (float4(myLight.color, 1));
                float lightAten = dot(lightDir, normalDir);
                float halfLambert = lightAten * 0.5 + 0.5;
                float3 rampCol = SAMPLE_TEXTURE2D(_RampTexture, sampler_RampTexture, float2(halfLambert, _SSS));
                return lightColor * float4(rampCol, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}