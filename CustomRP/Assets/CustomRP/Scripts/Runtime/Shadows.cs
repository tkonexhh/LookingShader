using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{

    struct ShadowedDirectionalLight
    {
        public int visibleLightIndex;
        public float slopeScaleBias;
        public float nearPlaneOffset;
    }


    const string bufferName = "Shadows";
    const int maxShadowedDirectionalLightCount = 4;//定向光阴影数量
    const int maxCascades = 4;//级联阴影的最大级数

    static string[] directionalFilterKeywords = {
        "_DIRECTIONAL_PCF3",
        "_DIRECTIONAL_PCF5",
        "_DIRECTIONAL_PCF7", };

    static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");
    static int dirShadowMatricesID = Shader.PropertyToID("_DirectionalShadowMatrices");
    static int cascadeCountID = Shader.PropertyToID("_CascadeCount");
    static int cascadeCullingSpheresID = Shader.PropertyToID("_CascadeCullingSpheres");//级联剔除球
    static int cascadeDataID = Shader.PropertyToID("_CascadeData");
    static int shadowAtlasSizeID = Shader.PropertyToID("_ShadowAtlasSize");
    static int shadowDistanceFadeID = Shader.PropertyToID("_ShadowDistanceFade");//阴影淡入度

    static Vector4[] cascadeCullingSpheres = new Vector4[maxCascades];
    static Vector4[] cascadeDatas = new Vector4[maxCascades];

    static Matrix4x4[] dirShadowMatrices = new Matrix4x4[maxShadowedDirectionalLightCount * maxCascades];//阴影矩阵 每一个级联都有阴影矩阵

    ShadowedDirectionalLight[] shadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];

    int shadowedDirectionalLightCount;
    CommandBuffer buffer = new CommandBuffer() { name = bufferName };

    ScriptableRenderContext context;
    CullingResults cullingResults;
    ShadowSettings shadowSettings;

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSetting)
    {
        this.context = context;
        this.cullingResults = cullingResults;
        this.shadowSettings = shadowSetting;
        shadowedDirectionalLightCount = 0;
    }

    public void CleanUp()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }

    public Vector3 ReserveDirectionalShadows(Light light, int visibleLightIndex)
    {
        if (shadowedDirectionalLightCount < maxShadowedDirectionalLightCount
        && light.shadows != LightShadows.None && light.shadowStrength > 0f//灯光的阴影模式设置为无或阴影强度为零 不用产生阴影
        && cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))//判断灯光的阴影是否可见
        {
            shadowedDirectionalLights[shadowedDirectionalLightCount] = new ShadowedDirectionalLight()
            {
                visibleLightIndex = visibleLightIndex,
                slopeScaleBias = light.shadowBias,
                nearPlaneOffset = light.shadowNearPlane
            };
            return new Vector3(
                light.shadowStrength,
                shadowSettings.directional.cascadeCount * shadowedDirectionalLightCount++,
                light.shadowNormalBias);
        }

        return Vector3.zero;
    }

    public void Render()
    {
        if (shadowedDirectionalLightCount > 0)
        {
            RenderDirectionalShadows();
        }
    }

    void RenderDirectionalShadows()
    {
        int atlasSize = (int)shadowSettings.directional.atlasSize;
        //将阴影绘制到贴图中
        buffer.GetTemporaryRT(dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.ClearRenderTarget(true, false, Color.clear);
        buffer.BeginSample(bufferName);
        ExecuteBuffer();

        //多灯光的阴影贴图被旋绕到了同一贴图上，结果被重叠了，所以需要拆分
        int tiles = shadowedDirectionalLightCount * shadowSettings.directional.cascadeCount;
        int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
        int tileSize = atlasSize / split;//重新计算图块尺寸

        for (int i = 0; i < shadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, split, tileSize);
        }
        //级联阴影
        buffer.SetGlobalInt(cascadeCountID, shadowSettings.directional.cascadeCount);
        buffer.SetGlobalVectorArray(cascadeCullingSpheresID, cascadeCullingSpheres);
        buffer.SetGlobalVectorArray(cascadeDataID, cascadeDatas);
        buffer.SetGlobalMatrixArray(dirShadowMatricesID, dirShadowMatrices);
        float f = 1f - shadowSettings.directional.cascadeFade;
        buffer.SetGlobalVector(shadowDistanceFadeID, new Vector4(1f / shadowSettings.maxDistance, 1f / shadowSettings.distanceFade, 1f / (1f - f * f)));
        SetKeywords();
        buffer.SetGlobalVector(shadowAtlasSizeID, new Vector4(atlasSize, 1f / atlasSize));
        buffer.EndSample(bufferName);
        ExecuteBuffer();
    }

    void SetKeywords()
    {
        int enabledIndex = (int)shadowSettings.directional.filter - 1;
        for (int i = 0; i < directionalFilterKeywords.Length; i++)
        {
            if (i == enabledIndex)
            {
                buffer.EnableShaderKeyword(directionalFilterKeywords[i]);
            }
            else
            {
                buffer.DisableShaderKeyword(directionalFilterKeywords[i]);
            }
        }
    }


    void RenderDirectionalShadows(int index, int split, int tileSize)
    {
        ShadowedDirectionalLight light = shadowedDirectionalLights[index];
        var shadowSetting = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);

        int cascadeCount = shadowSettings.directional.cascadeCount;
        int tileOffset = index * cascadeCount;
        Vector3 ratios = shadowSettings.directional.CascadeRatios;

        for (int i = 0; i < cascadeCount; i++)
        {
            cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(light.visibleLightIndex, i, cascadeCount, ratios, tileSize, light.nearPlaneOffset,
                        out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData);
            shadowSetting.splitData = splitData;
            if (index == 0)//只需要对第一个光源执行此操作，因为所有光源的级联都是等效的
            {
                SetCascadeData(index, splitData.cullingSphere, tileSize);
            }
            int tileIndex = tileOffset + i;
            var offset = SetTileViewport(tileIndex, split, tileSize);
            Matrix4x4 WtL = projectionMatrix * viewMatrix;//世界空间到灯光空间的转换矩阵
            dirShadowMatrices[tileIndex] = ConvertToAtlasMatrix(WtL, offset, split);


            buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
            buffer.SetGlobalDepthBias(0f, light.slopeScaleBias);
            ExecuteBuffer();
            context.DrawShadows(ref shadowSetting);
            buffer.SetGlobalDepthBias(0f, 0f);
        }

    }

    void SetCascadeData(int index, Vector4 cullingSphere, float tileSize)
    {
        float texelSize = 2f * cullingSphere.w / tileSize;
        float filterSize = texelSize * ((float)shadowSettings.directional.filter + 1f);
        cullingSphere.w -= filterSize;
        cullingSphere.w *= cullingSphere.w;
        cascadeCullingSpheres[index] = cullingSphere;
        cascadeDatas[index] = new Vector4(1f / cullingSphere.w, filterSize * 1.4142136f);
    }

    /// <summary>
    /// 从世界空间转换为阴影图块空间的矩阵
    /// </summary>
    /// <param name="m"></param>
    /// <param name="offset"></param>
    /// <param name="split"></param>
    /// <returns></returns>
    Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
    {
        if (SystemInfo.usesReversedZBuffer)//如果反向 Z buffer
        {
            m.m20 = -m.m20;
            m.m21 = -m.m21;
            m.m22 = -m.m22;
            m.m23 = -m.m23;
        }
        ///????????
        float scale = 1f / split;
        m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
        m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
        m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
        m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
        m.m10 = (0.5f * (m.m10 + m.m30) + offset.x * m.m30) * scale;
        m.m11 = (0.5f * (m.m11 + m.m31) + offset.x * m.m31) * scale;
        m.m12 = (0.5f * (m.m12 + m.m32) + offset.x * m.m32) * scale;
        m.m13 = (0.5f * (m.m13 + m.m33) + offset.x * m.m33) * scale;

        m.m20 = 0.5f * (m.m20 + m.m30);
        m.m21 = 0.5f * (m.m21 + m.m31);
        m.m22 = 0.5f * (m.m22 + m.m32);
        m.m23 = 0.5f * (m.m23 + m.m33);
        return m;
    }


    Vector2 SetTileViewport(int index, int split, float tileSize)
    {
        Vector2 offset = new Vector2(index % split, index / split);
        buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
        return offset;
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
}
