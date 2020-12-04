Shader "XHH/Lambert"
{
    Properties
    {

        [Toggle(_Half)]
        _Half ("Half Lambert", float) = 1
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
            #pragma shader_feature _Half

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial);
            CBUFFER_END


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
                float3 viewDirWS: TEXCOORD1;
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
                float4 lightColor = float4(myLight.color, 1);
                float lightAten = (dot(lightDir, input.normalWS));
                #ifdef _Half
                    return lightColor * (lightAten * 0.5 + 0.5);//Hald - Lambert
                #else
                    lightAten = saturate(lightAten);
                    return lightColor * lightAten;
                #endif
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}