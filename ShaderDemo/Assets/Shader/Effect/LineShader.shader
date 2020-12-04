Shader "XHH/LineShader"
{
    Properties
    {
        _Width ("Width", Range(0, 0.2)) = 0.1
        _FillCol ("FillCol", Color) = (1, 1, 1, 1)
        _Index ("间隔", Range(1, 200)) = 1
        _Offset ("间距", Range(0, 1)) = 0
        _ScaleX ("物体缩放X", float) = 1
        _ScaleY ("物体缩放X", float) = 1
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            //------------
            //Unity defined keywords

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            
            CBUFFER_START(UnityPerMaterial);
            float _Index, _Offset;
            float _Width;
            float _ScaleX, _ScaleY;
            float4 _FillCol;
            CBUFFER_END


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
                half4 tex = half4(0, 0, 0, 0);
                float y = input.uv.y;
                float x = input.uv.x;
                
                float widthY = _Width / _ScaleY;
                float widthX = _Width / _ScaleX;
                float width = _Width;
                float minWidth = min(widthX, widthY);
                float maxWidth = max(widthX, widthY);
                if (!(y > widthY && y < 1 - widthY) && (x > widthX * 2 && x < 1 - widthX * 2))
                {
                    tex = round(sin(x * _Index * _ScaleX) + _Offset);
                }
                else if (!(x > widthX && x < 1 - widthX) && (y > widthX * 2 && y < 1 - widthX * 2))
                {
                    tex = round(sin(-y * _Index * _ScaleY) + _Offset);
                }

                //四个角
                //左下角
                if (x < widthX * 2 && y < widthY * 2)
                {
                    if ((x > widthX && y < widthY) || (x < widthX && y > width))
                    {
                        tex = half4(1, 1, 1, 1);
                    }
                    else if (x < widthX && y < widthY)
                    {
                        //TODO处理圆角
                        float newX = minWidth - x;
                        float newY = minWidth - y;
                        if ((newX * newX + newY * newY) < minWidth * minWidth)
                            tex = half4(1, 1, 1, 1);
                    }
                }
                
                //右下角
                if (x > 1 - widthX * 2 && y < widthY * 2)
                {
                    if ((x > 1 - widthX && y > widthY) || (x < 1 - widthX && y < widthY))
                    {
                        tex = half4(1, 1, 1, 1);
                    }
                    else if (x > 1 - widthX && y < widthY)
                    {
                        // //TODO处理圆角
                        float newX = x - 1 + maxWidth;
                        float newY = maxWidth - y;
                        if ((newX * newX + newY * newY) < maxWidth * maxWidth)
                            tex = half4(1, 1, 1, 1);
                    }
                }
                

                //左上角
                if (x < widthX * 2 && y > 1 - widthY * 2)
                {
                    // tex = half4(1, 1, 1, 1);
                    if ((x > widthX && y > 1 - widthY) || (x < widthX && y < 1 - widthY))
                    {
                        tex = half4(1, 1, 1, 1);
                    }
                    else if (x < widthX && y > 1 - widthY)
                    {
                        float newX = minWidth - x;
                        float newY = y - 1 + minWidth;
                        if ((newX * newX + newY * newY) < (maxWidth) * (maxWidth))
                            tex = half4(1, 1, 1, 1);
                    }
                }

                //右上角
                if (x > 1 - widthX * 2 && y > 1 - widthY * 2)
                {
                    //
                    if ((x > 1 - widthX && y < 1 - widthY) || (x < 1 - widthX && y > 1 - widthY))
                    {
                        tex = half4(1, 1, 1, 1);
                    }
                    else if (x > 1 - widthX && y > 1 - widthY)
                    {
                        float newX = x - 1 + maxWidth;;
                        float newY = y - 1 + maxWidth;
                        if ((newX * newX + newY * newY) < (maxWidth) * (maxWidth))
                            tex = half4(1, 1, 1, 1);
                    }
                }

                

                //中间填色
                if (x > widthX && x < 1 - widthX && y > widthY && y < 1 - widthY)
                {
                    tex = _FillCol;
                }

                
                return tex;
                
                // return float4(tex.rgb, 0.2);
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}







