Shader "XHH/Rain"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _NormalTex ("NormalTex", 2D) = "bump" { }

        [Header(Rain)]
        _RainTex ("RainTex", 2D) = "white" { }
        _RainSpeed ("Speed", float) = 0.5
        _SlopeTilling ("SlopeTilling", float) = 1
        _RainStrength ("RainStrength", Range(0, 5)) = 1
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
            float _RainSpeed, _RainWidth, _SlopeTilling, _RainStrength;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_RainTex);SAMPLER(sampler_RainTex);
            TEXTURE2D(_NormalTex);
            
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
                float3 centerPosWS: TEXCOORD2;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
                float3 tangentWS: TEXCOORD3;
                float3 bitangetWS: TEXCOORD4;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.centerPosWS = TransformObjectToWorld(float3(0, 0, 0));
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;

                return output;
            }

            float4 frag(Varyings input): SV_Target
            {
                
                //处理水面涟漪
                float2 rainUI = (input.positionWS.xz - input.centerPosWS.xz) ;
                half4 var_RainTex = SAMPLE_TEXTURE2D(_RainTex, sampler_RainTex, rainUI);
                half4 var_RainTex2 = SAMPLE_TEXTURE2D(_RainTex, sampler_RainTex, rainUI + float2(0.5, 0.5));
                
                float rainSpeed = _RainSpeed * 3;
                float emissive = var_RainTex.r - saturate(1 - frac(_Time.x * rainSpeed));
                float maskColor = saturate(smoothstep(0, 1, 1 - distance(emissive, 0.05) / 0.05)) ;
                
                float emissive2 = var_RainTex2.r - saturate((1 - frac(_Time.x * rainSpeed + 0.5)));
                float maskColor2 = saturate(smoothstep(0, 1, 1 - distance(emissive2, 0.05) / 0.05));
                
                float maskSwitch = abs(frac(_Time.x * rainSpeed - 0.5) - 0.5);
                float maskSwitch2 = abs(frac(_Time.x * rainSpeed) - 0.5);
                
                float rain = maskColor2 * maskSwitch2 + maskColor * maskSwitch;
                // return rain;
                float3 verticalPos = (input.positionWS - input.centerPosWS) / _SlopeTilling;
                float2 verticalUVMove = verticalPos.xy - float2(0, _Time.x * - _RainSpeed);
                float2 verticalUVMove2 = verticalPos.zy - float2(0, _Time.x * - _RainSpeed);
                half4 var_RainTex_Slope1 = SAMPLE_TEXTURE2D(_RainTex, sampler_RainTex, verticalPos.xy);
                half4 var_RainTex_Slope2 = SAMPLE_TEXTURE2D(_RainTex, sampler_RainTex, verticalPos.zy);
                
                half4 var_RainTex_Move1 = SAMPLE_TEXTURE2D(_RainTex, sampler_RainTex, verticalUVMove);
                half4 var_RainTex_Move2 = SAMPLE_TEXTURE2D(_RainTex, sampler_RainTex, verticalUVMove2);

                float normalX = clamp(0, 1, abs(input.normalWS.x));
                

                float slope = lerp((var_RainTex_Move1.b - 0.5) * var_RainTex_Slope1.g, (var_RainTex_Move2.b - 0.5) * var_RainTex_Slope2.g, normalX);

                float upMask = saturate((input.normalWS.y - 0.5) * 2);
                float downMask = saturate( - (input.normalWS.y - 0.2));
                float sideMask = saturate(1 - upMask - downMask);
                // return sideMask * slope;
                // return upMask * rain;
                float rainEffect = saturate(upMask * rain + sideMask * slope) * _RainStrength;
                // return rainEffect;
                half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return float4(var_MainTex.rgb * 0.4 + rainEffect, 1) ;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
