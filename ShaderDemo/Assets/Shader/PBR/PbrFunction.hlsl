#ifndef PBR_Function_INCLUDE
    #define PBR_Function_INCLUDE
    //D项 法线微表面分布函数
    float D_Function(float NdotH, float roughness)
    {
        float a2 = roughness * roughness;
        float NdotH2 = NdotH * NdotH;
        
        //直接根据公式来
        float nom = a2;//分子
        float denom = NdotH2 * (a2 - 1) + 1;//分母
        denom = denom * denom * PI;
        return nom / denom;
    }

    //G项子项
    float G_section(float dot, float k)
    {
        float nom = dot;
        float denom = lerp(dot, 1, k);
        return nom / denom;
    }

    //G项
    float G_Function(float NdotL, float NdotV, float roughness)
    {
        float k = pow(1 + roughness, 2) / 8;
        float Gnl = G_section(NdotL, k);
        float Gnv = G_section(NdotV, k);
        return Gnl * Gnv;
    }

    //F项 直接光
    real3 F_Function(float HdotL, float3 F0)
    {
        float Fre = exp2((-5.55473 * HdotL - 6.98316) * HdotL);
        return lerp(Fre, 1, F0);
    }

    //F项 间接光
    real3 IndirF_Function(float NdotV, float3 F0, float roughness)
    {
        float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
        return F0 + Fre * saturate(1 - roughness - F0);
    }

    //间接光漫反射 球谐函数 光照探针
    real3 SH_IndirectionDiff(float3 normalWS)
    {
        real4 SHCoefficients[7];
        SHCoefficients[0] = unity_SHAr;
        SHCoefficients[1] = unity_SHAg;
        SHCoefficients[2] = unity_SHAb;
        SHCoefficients[3] = unity_SHBr;
        SHCoefficients[4] = unity_SHBg;
        SHCoefficients[5] = unity_SHBb;
        SHCoefficients[6] = unity_SHC;
        float3 Color = SampleSH9(SHCoefficients, normalWS);
        return max(0, Color);
    }

    //间接光高光 反射探针
    real3 IndirSpeCube(float3 normalWS, float3 viewWS, float roughness, float AO)
    {
        float3 reflectDirWS = reflect(-viewWS, normalWS);
        roughness = roughness * (1.7 - 0.7 * roughness);//Unity内部不是线性 调整下拟合曲线求近似
        float MidLevel = roughness * 6;//把粗糙度remap到0-6 7个阶级 然后进行lod采样
        float4 speColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirWS, MidLevel);//根据不同的等级进行采样
        #if !defined(UNITY_USE_NATIVE_HDR)
            return DecodeHDREnvironment(speColor, unity_SpecCube0_HDR) * AO;//用DecodeHDREnvironment将颜色从HDR编码下解码。可以看到采样出的rgbm是一个4通道的值，最后一个m存的是一个参数，解码时将前三个通道表示的颜色乘上xM^y，x和y都是由环境贴图定义的系数，存储在unity_SpecCube0_HDR这个结构中。
        #else
            return speColor.xyz * AO;
        #endif
    }

    //间接高光 曲线拟合 放弃LUT采样而使用曲线拟合
    real3 IndirSpeFactor(float roughness, float smoothness, float3 BRDFspe, float3 F0, float NdotV)
    {
        #ifdef UNITY_COLORSPACE_GAMMA
            float SurReduction = 1 - 0.28 * roughness, roughness;
        #else
            float SurReduction = 1 / (roughness * roughness + 1);
        #endif
        #if defined(SHADER_API_GLES)//Lighting.hlsl 261行
            float Reflectivity = BRDFspe.x;
        #else
            float Reflectivity = max(max(BRDFspe.x, BRDFspe.y), BRDFspe.z);
        #endif
        half GrazingTSection = saturate(Reflectivity + smoothness);
        float Fre = Pow4(1 - NdotV);//lighting.hlsl第501行
        //float Fre=exp2((-5.55473*NdotV-6.98316)*NdotV);//lighting.hlsl第501行 它是4次方 我是5次方
        return lerp(F0, GrazingTSection, Fre) * SurReduction;
    }
#endif