Shader "XHH/Water_Tessision"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
        _Amplitude ("Amplitude", Range(0, 4)) = 1//振幅
        _WaveLength ("Wave Length", float) = 10//波长
        _Speed ("Speed", float) = 1
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
            #pragma hull HS
            #pragma domain DS
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            float _Amplitude;
            float _WaveLength;
            float _Speed;

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
                float3 positionOS: TEXCOORD1;
                float2 uv: TEXCOORD0;
                float3 normalWS: NORMAL;
            };


            
            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 p = input.positionOS.xyz;
                float k = 2 * PI / _WaveLength;
                float f = k * (p.x - _Speed * _Time.y);
                p.y = _Amplitude * sin(f);
                input.positionOS.xyz = p;
                output.positionOS.xyz = input.positionOS.xyz;//TransformObjectToHClip(input.positionOS.xyz);

                float3 tangent = normalize(float3(1, k * _Amplitude * cos(f), 0));
                float3 normal = float3(-tangent.y, tangent.x, 0);
                input.normalOS = normal;

                output.normalWS = TransformObjectToWorldNormal(input.normalOS, true);
                output.uv = input.uv;


                return output;
            }

            ////////////***********曲面细分***********////////////////////
            struct PatchTess
            {
                float EdgeTess[3]: SV_TessFactor;
                float InsideTess: SV_InsideTessFactor;
            };
            PatchTess ConstantHS(InputPatch < Varyings, 3 > patch, uint patchID: SV_PrimitiveID)
            {
                PatchTess pt;
                pt.EdgeTess[0] = 15;
                pt.EdgeTess[1] = 15;
                pt.EdgeTess[2] = 15;
                pt.InsideTess = 15;
                return pt;
            }
            
            
            struct HullOut
            {
                float3 positionOS: TEXCOORD0;
                float3 normalWS: NORMAL;
            };
            
            [domain("tri")]
            [partitioning("integer")]
            [outputtopology("triangle_cw")]
            [outputcontrolpoints(3)]
            [patchconstantfunc("ConstantHS")]
            [maxtessfactor(64.0f)]
            HullOut HS(InputPatch < Varyings, 3 > p, uint i: SV_OutputControlPointID)
            {
                HullOut hout;
                hout.positionOS = p[i].positionOS;
                hout.normalWS = p[i].normalWS;
                return hout;
            }
            
            struct DomainOut
            {
                float4 positionOS: SV_POSITION;
                float3 normalWS: NORMAL;
            };
            [domain("tri")]
            DomainOut DS(PatchTess patchTess, float3 baryCoords: SV_DomainLocation, const OutputPatch < HullOut, 3 > triangles)
            {
                DomainOut dout;
                float3 p = triangles[0].positionOS * baryCoords.x + triangles[1].positionOS * baryCoords.y + triangles[2].positionOS * baryCoords.z;
                float3 n = triangles[0].normalWS * baryCoords.x + triangles[1].normalWS * baryCoords.y + triangles[2].normalWS * baryCoords.z;
                dout.positionOS = TransformObjectToHClip(p.xyz);
                dout.normalWS = n;
                return dout;
            }
            ////////////***********曲面细分***********////////////////////

            
            float4 frag(DomainOut input): SV_Target
            {
                Light light = GetMainLight();
                float3 lightDirWS = normalize(light.direction);
                float NdotL = saturate(dot(lightDirWS, input.normalWS));
                return NdotL;
                // half4 var_MainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return 1;
            }
            
            ENDHLSL
            
        }
    }
    FallBack "Diffuse"
}
