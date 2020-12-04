Shader "XHH/HalftoneShadow"
{
    Properties
    {
        
        _Tilling ("Tilling", int) = 10
        _Width ("Width", Range(-1, 0)) = 0
        _Min ("Min", Range(-2, 0)) = 0.7
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
            #include "../CustomHlsl/CustomHlsl.hlsl"
            
            CBUFFER_START(UnityPerMaterial);
            int _Tilling;
            float _Min, _Width;
            CBUFFER_END

            

            SAMPLER(_CameraDepthTexture);


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
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;
                
                return output;
            }

            float4 frag(Varyings input): SV_Target
            {
                float4 col;
                Light myLight = GetMainLight();
                float3 lightDir = normalize(myLight.direction);
                float4 lightColor = float4(myLight.color, 1);
                float ldotn = dot(lightDir, input.normalWS);
                // float halfLambert = lightAten * 0.5 + 0.5;
                float halfLambert = remap(ldotn, 1, _Width, _Min, 2);
                float2 screenUV = input.positionCS.xy / _ScreenParams.xy;
                float2 tileSum = _ScreenParams.xy / _Tilling;//input.positionCS.xy / _ScreenParams.xy * _Tilling;
                screenUV = screenUV * tileSum;
                screenUV = frac(screenUV);
                screenUV = remap(screenUV, 0, 1.0, -0.5, 0.5);
                
                float length = (screenUV.x * screenUV.x + screenUV.y * screenUV.y);
                // length = 1 - length;
                float c = pow(length, halfLambert);
                c = round(c);
                return c ;
                return float4(screenUV.x, screenUV.y, 0, 1);//lerpColor + texCol;//lerp(lightColor, texCol, halfLambert);//float4(screenUV, 1, 1);//Hald - Lambert
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}