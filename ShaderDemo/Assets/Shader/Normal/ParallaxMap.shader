Shader "XHH/Bump/ParallaxMap"
{
    Properties
    {
        _AbledoMap ("MainTex", 2D) = "white" { }
        [Normal]_NormalMap ("NormalTex", 2D) = "bump" { }
        _ParallaxMap ("ParallaxTex", 2D) = "black" { }
        _HeightScale ("Height Scale", Range(0, 2)) = 1
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
            float _HeightScale;
            CBUFFER_END

            TEXTURE2D(_AbledoMap);
            TEXTURE2D(_NormalMap);SAMPLER(sampler_NormalMap);
            TEXTURE2D(_ParallaxMap);
            
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
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 tangentWS: TEXCOORD2;
                float3 btangentWS: TEXCOORD3;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
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
                float4 var_Albedo = SAMPLE_TEXTURE2D(_AbledoMap, sampler_NormalMap, input.uv);
                Light light = GetMainLight();
                float3 lDir = normalize(light.direction);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);

                //Height
                float height = SAMPLE_TEXTURE2D(_ParallaxMap, sampler_NormalMap, input.uv);
                float2 heightUV = viewDir.xy / viewDir.z * height * _HeightScale;
                float2 newUV = input.uv - heightUV;
                // return float4(heightUV, 0, 1);

                float3 nDirTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, newUV));
                float3x3 TBN = float3x3(input.tangentWS, input.btangentWS, input.normalWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));

                
                
                float ndotl = dot(nDirWS, lDir);
                float lambert = saturate(ndotl);
                float3 lightCol = light.color;
                float3 lambertCol = var_Albedo.rgb * lightCol * lambert;
                float4 finalCol = float4(lambertCol, 1);

                
                // return height;


                return finalCol;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
