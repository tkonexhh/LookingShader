Shader "XHH/Phong"
{
    Properties
    {
        _SpecularRange ("SpecularRange", Range(1, 100)) = 10
        _SpecularColor ("SpecularColor", Color) = (1, 1, 1, 1)
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
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial);
            float _SpecularRange;
            float4 _SpecularColor;
            CBUFFER_END

            float4 _CameraColorTexture_TexelSize; SAMPLER(_CameraColorTexture);


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
                input.normalWS = normalize(input.normalWS);
                Light myLight = GetMainLight();
                float3 lightDir = normalize(myLight.direction);
                float4 lightColor = saturate(float4(myLight.color, 1));
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 rDir = normalize(reflect(-lightDir, input.normalWS));
                
                float3 rDir2 = normalize(reflect(-lightDir - float3(0, 1.5, 0), input.normalWS));


                float lambert = dot(lightDir, input.normalWS);
                float halfLambert = lambert * 0.5 + 0.5;

                //高光
                float specular = max(0, dot(rDir, input.normalWS));
                float4 specularCol = pow(specular, _SpecularRange) * _SpecularColor;

                float specular2 = max(0, dot(rDir2, input.normalWS));
                float4 specularCol2 = pow(specular2, _SpecularRange * 2) * _SpecularColor;
                return specularCol + specularCol2;

                float4 diffuseCol = saturate((lightColor * lambert));
                float4 finalCol = diffuseCol + specularCol;
                return finalCol;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}