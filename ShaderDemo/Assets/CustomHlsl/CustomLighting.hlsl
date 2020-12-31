#ifndef CUSTOM_LIGHTING
    #define CUSTOM_LIGHTING

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    //---------------------------
    //helper functions
    float MixFunction(float i, float j, float x)
    {
        return j * x + i * (1.0 - x);
    }
    float2 MixFunction(float2 i, float2 j, float x)
    {
        return j * x + i * (1.0h - x);
    }
    float3 MixFunction(float3 i, float3 j, float x)
    {
        return j * x + i * (1.0h - x);
    }
    float MixFunction(float4 i, float4 j, float x)
    {
        return j * x + i * (1.0h - x);
    }


    // -------------------------------------
    // 高光Specular
    // 各种NDF函数(法线分布函数)
    float BlinnPhongNDF(float NdotH, float specularGloss, float specularpower)
    {
        float Distribution = pow(NdotH, specularGloss) * specularpower;
        Distribution *= (2 + specularpower) / (2 * 3.1415926535);
        return Distribution;
    }

    float PhongNDF(float rdotv, float specularGloss, float specularpower)
    {
        float phong = pow(rdotv, specularGloss) * specularpower;
        return phong;
    }

    float BeckmannNDF(float roughness, float NdotH)
    {
        float roughnessSqr = roughness * roughness;
        float NdotHSqr = NdotH * NdotH;
        return max(0.000001, (1.0 / (3.1415926535 * roughnessSqr * NdotHSqr * NdotHSqr)) * exp((NdotHSqr - 1) / (roughnessSqr * NdotHSqr)));
    }


    float GaussianNDF(float roughness, float NdotH)
    {
        float roughnessSqr = roughness * roughness;
        float thetaH = acos(NdotH);
        return exp(-thetaH * thetaH / roughnessSqr);
    }

    float GGXNDF(float roughness, float NdotH)
    {
        float roughnessSqr = roughness * roughness;
        float NdotHSqr = NdotH * NdotH;
        float TanNdotHSqr = (1 - NdotHSqr) / NdotHSqr;
        return(1.0 / 3.1415926535) * sqrt(roughness / (NdotHSqr * (roughnessSqr + TanNdotHSqr)));
    }

    float TrowbridgeReitzNDF(float NdotH, float roughness)
    {
        float roughnessSqr = roughness * roughness;
        float Distribution = NdotH * NdotH * (roughnessSqr - 1.0) + 1.0;
        return roughnessSqr / (3.1415926535 * Distribution * Distribution);
    }

    // 各向异性NDF
    float TrowbridgeReitzAnisotropicNDF(float anisotropic, float roughness, float NdotH, float HdotX, float HdotY)
    {
        float aspect = sqrt(1.0h - anisotropic * 0.9h);
        float X = max(.001, sqrt(1.0 - roughness) / aspect) * 5;
        float Y = max(.001, sqrt(1.0 - roughness) * aspect) * 5;
        return 1.0 / (3.1415926535 * X * Y * sqrt(sqrt(HdotX / X) + sqrt(HdotY / Y) + NdotH * NdotH));
    }

    //---------------------------
    //几何阴影函数 GSF

    float ImplicitGSF(float NdotL, float NdotV)
    {
        float Gs = (NdotL * NdotV);
        return Gs;
    }

    //设计用于各向异性
    float AshikhminShirleyGSF(float NdotL, float NdotV, float LdotH)
    {
        float Gs = NdotL * NdotV / (LdotH * max(NdotL, NdotV));
        return(Gs);
    }
    // 设计用于各向同性
    float AshikhminPremozeGSF(float NdotL, float NdotV)
    {
        float Gs = NdotL * NdotV / (NdotL + NdotV - NdotL * NdotV);
        return(Gs);
    }

    float DuerGSF(float3 lightDirection, float3 viewDirection, float3 normalDirection, float NdotL, float NdotV)
    {
        float3 LpV = lightDirection + viewDirection;
        float Gs = dot(LpV, LpV) * pow(dot(LpV, normalDirection), -4);
        return(Gs);
    }

    float NeumannGSF(float NdotL, float NdotV)
    {
        float Gs = (NdotL * NdotV) / max(NdotL, NdotV);
        return(Gs);
    }

    float KelemenGSF(float NdotL, float NdotV, float LdotV, float VdotH)
    {
        float Gs = (NdotL * NdotV) / (VdotH * VdotH);
        return(Gs);
    }

    float ModifiedKelemenGSF(float NdotV, float NdotL, float roughness)
    {
        float c = 0.797884560802865;    	// c = sqrt(2 / Pi)
        float k = roughness * roughness * c;
        float gH = NdotV * k + (1 - k);
        return(gH * gH * NdotL);
    }

    //Cook-Torrance几何阴影函数是为了解决三种几何衰减的情况而创造出来的。
    //第一种情况是光在没有被干涉的情况下进行反射，
    //第二种是反射的光在反射完之后被阻挡了，
    //第三种情况是有些光在到达下一个微表面之前被阻挡了
    float CookTorrenceGSF(float NdotL, float NdotV, float VdotH, float NdotH)
    {
        float Gs = min(1.0, min(2 * NdotH * NdotV / VdotH, 2 * NdotH * NdotL / VdotH));
        return(Gs);
    }

    //Ward GSF是加强版的Implicit GSF。它非常适合用于突出当视角与平面角度发生改变后各向异性带的表现。
    float WardGSF(float NdotL, float NdotV, float VdotH, float NdotH)
    {
        float Gs = pow(NdotL * NdotV, 0.5);
        return(Gs);
    }

    //Kurt GSF又是另一种各向异性的GSF，这个模型用于帮助控制基于粗糙度的各向异性表面描述。这个模型追求能量守恒，特别是切线角部分。
    float KurtGSF(float NdotL, float NdotV, float VdotH, float roughness)
    {
        float Gs = NdotL * NdotV / (VdotH * pow(NdotL * NdotV, roughness));
        return(Gs);
    }

    float WalterEtAlGSF(float NdotL, float NdotV, float roughness)
    {
        float alphaSqr = roughness * roughness;
        float NdotLSqr = NdotL * NdotL;
        float NdotVSqr = NdotV * NdotV;
        float SmithL = 2 / (1 + sqrt(1 + alphaSqr * (1 - NdotLSqr) / (NdotLSqr)));
        float SmithV = 2 / (1 + sqrt(1 + alphaSqr * (1 - NdotVSqr) / (NdotVSqr)));
        float Gs = (SmithL * SmithV); return Gs;
    }

    float GGXGSF(float NdotL, float NdotV, float roughness)
    {
        float roughnessSqr = roughness * roughness;
        float NdotLSqr = NdotL * NdotL;
        float NdotVSqr = NdotV * NdotV;
        float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotLSqr));
        float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr + (1 - roughnessSqr) * NdotVSqr));
        float Gs = (SmithL * SmithV); return Gs;
    }

    float SchlickGSF(float NdotL, float NdotV, float roughness)
    {
        float roughnessSqr = roughness * roughness;
        float SmithL = (NdotL) / (NdotL * (1 - roughnessSqr) + roughnessSqr); float SmithV = (NdotV) / (NdotV * (1 - roughnessSqr) + roughnessSqr);
        return(SmithL * SmithV);
    }

    float SchlickBeckmanGSF(float NdotL, float NdotV, float roughness)
    {
        float roughnessSqr = roughness * roughness;
        float k = roughnessSqr * 0.797884560802865;
        float SmithL = (NdotL) / (NdotL * (1 - k) + k);
        float SmithV = (NdotV) / (NdotV * (1 - k) + k);
        float Gs = (SmithL * SmithV); return Gs;
    }


    //---------------------------
    //Fresnel
    float SchlickFresnel(float i)
    {
        float x = clamp(1.0 - i, 0.0, 1.0);
        float x2 = x * x;
        return x2 * x2 * x;
    }

    float3 FresnelLerp(float3 x, float3 y, float d)
    {
        float t = SchlickFresnel(d);
        return lerp(x, y, t);
    }

    float3 SchlickFresnelFunction(float3 SpecularColor, float LdotH)
    {
        return SpecularColor + (1 - SpecularColor) * SchlickFresnel(LdotH);
    }

    float SchlickIORFresnelFunction(float ior, float LdotH)
    {
        float f0 = pow((ior - 1) / (ior + 1), 2);
        return f0 + (1 - f0) * SchlickFresnel(LdotH);
    }

    float SphericalGaussianFresnelFunction(float LdotH, float SpecularColor)
    {
        float power = ((-5.55473 * LdotH) - 6.98316) * LdotH;
        return SpecularColor + (1 - SpecularColor) * pow(2, power);
    }

    //normal incidence reflection calculation
    float F0(float NdotL, float NdotV, float LdotH, float roughness)
    {
        // Diffuse fresnel
        float FresnelLight = SchlickFresnel(NdotL);
        float FresnelView = SchlickFresnel(NdotV);
        float FresnelDiffuse90 = 0.5 + 2.0 * LdotH * LdotH * roughness;
        return MixFunction(1, FresnelDiffuse90, FresnelLight) * MixFunction(1, FresnelDiffuse90, FresnelView);
    }


#endif
