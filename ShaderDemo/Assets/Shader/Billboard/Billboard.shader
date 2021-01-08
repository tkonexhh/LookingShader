Shader "XHH/Billboard"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull off
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)


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
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;
                //重新定义一个Z轴
                float3 newZ = TransformWorldToObject(_WorldSpaceCameraPos);
                newZ = normalize(newZ);

                //新的Y轴定义为
                
                //那么 newX 就可以cross得到
                
                float3 newX = normalize(abs(newZ.y) < 0.99?cross(float3(0, 1, 0), newZ): cross(newZ, float3(0, 1, 0)));

                float3 newY = normalize(cross(newZ, newX));

                float3x3 cameraMatrix = float3x3(newX, newY, newZ);
                float3 newPos = mul(input.positionOS.xyz, cameraMatrix);

                output.positionCS = TransformObjectToHClip(newPos);
                // output.positionCS = TransformObjectToHClip(input.positionOS);
                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return 1;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
