Shader "XHH/TBNNormalMap"
{
    Properties
    {
        _NormalMap ("NormalTex", 2D) = "white" { }
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
            
            CBUFFER_END

            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            
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
                float3 tangentWS: TEXCOORD2;
                float3 btangentWS: TEXCOORD3;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                //将切线从OS撞到WS
                output.tangentWS = TransformObjectToWorld(input.tangentOS.xyz);
                //副切线通过法线和切线差乘cross得到
                output.btangentWS = normalize(cross(output.tangentWS, output.normalWS) * input.tangentOS.w);
                output.uv = input.uv;

                return output;
            }


            float4 frag(Varyings input): SV_Target
            {
                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv));
                float3x3 TBN = float3x3(input.tangentWS, input.btangentWS, input.normalWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));

                Light light = GetMainLight();
                float3 lDir = normalize(light.direction);
                
                float ndotl = dot(nDirWS, lDir);
                float lambert = saturate(ndotl);
                float3 lightCol = light.color;
                float3 lambertCol = lightCol * lambert;
                float4 finalCol = float4(lambertCol, 1);
                return finalCol;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
