Shader "XHH/ScreenUV"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "White" { }
        _ScreenTex ("ScreenTex", 2D) = "white" { }
        _Step ("Step", Range(0, 1)) = 0.1
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
            #include "../../CustomHlsl/CustomHlsl.hlsl"
            
            CBUFFER_START(UnityPerMaterial)


            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_ScreenTex);SAMPLER(sampler_ScreenTex);float4 _ScreenTex_ST;

            float _Step;
            
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
                float2 screenUV: TEXCOORD2;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;
                
                
                float3 positionVS = TransformObjectToView(input.positionOS.xyz);
                float originPos = mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1)).z;
                output.screenUV = positionVS.xy / positionVS.z;
                output.screenUV *= originPos;
                return output;
            }


            


            float4 frag(Varyings input): SV_Target
            {

                Light light = GetMainLight();
                float3 lDirWS = normalize(light.direction);

                float ndotl = dot(input.normalWS, lDirWS);
                float lambert = saturate(ndotl);
                // return 1 - step(0.1, lambert);
                
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                half4 var_ScreenTex = SAMPLE_TEXTURE2D(_ScreenTex, sampler_ScreenTex, input.screenUV * _ScreenTex_ST.xy + _ScreenTex_ST.zw);
                
                float3 diffuse = var_MainTex.rgb * lambert;
                float3 dark = var_ScreenTex.rgb  ;


                float3 finalRGB = lerp(dark, diffuse, saturate(lambert + _Step));
                
                return float4(finalRGB, 1);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
