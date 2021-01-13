Shader "Custom RP/Unlit"
{
    Properties
    {
        _BaseColor ("BaseColor", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        
        Pass
        {
            HLSLPROGRAM
            
            #pragma vertex UnlitPassVertex
            #pragma fragment UnlitPassFragment
            
            // #include "UnityCG.cginc"
            #include "UnlitPass.hlsl"

            // struct appdata
            // {
                //     float4 vertex: POSITION;
                //     float2 uv: TEXCOORD0;
                // };

                // struct v2f
                // {
                    //     float2 uv: TEXCOORD0;
                    //     float4 vertex: SV_POSITION;
                    // };


                    // v2f vert(appdata v)
                    // {
                        //     v2f o;
                        //     o.vertex = UnityObjectToClipPos(v.vertex);
                        //     return o;
                        // }

                        // fixed4 frag(v2f i): SV_Target
                        // {

                            //     return 1;
                            // }
                            ENDHLSL
                            
                        }
                    }
                }
