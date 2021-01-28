using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{

    struct ShadowedDirectionalLight
    {
        public int visibleLightIndex;
    }


    const string bufferName = "Shadows";
    CommandBuffer buffer = new CommandBuffer() { name = bufferName };


    ScriptableRenderContext context;
    CullingResults cullingResults;
    ShadowSettings shadowSettings;

    const int maxShadowedDirectionalLightCount = 1;//定向光阴影数量
    int shadowedDirectionalLightCount;

    static int dirShadowAtlasId = Shader.PropertyToID("-DirectionalShadowAtlas");

    ShadowedDirectionalLight[] shadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];




    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSetting)
    {
        this.context = context;
        this.cullingResults = cullingResults;
        this.shadowSettings = shadowSetting;

        shadowedDirectionalLightCount = 0;
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    public void Render()
    {
        if (shadowedDirectionalLightCount > 0)
        {
            RenderDirectionalShadows();
        }
    }

    public void CleanUp()
    {
        if (shadowedDirectionalLightCount > 0)
        {
            buffer.ReleaseTemporaryRT(dirShadowAtlasId);
            ExecuteBuffer();
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

        for (int i = 0; i < shadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, atlasSize);
        }
        buffer.EndSample(bufferName);
        ExecuteBuffer();
    }

    void RenderDirectionalShadows(int indexx, int tileSize)
    {
        ShadowedDirectionalLight light = shadowedDirectionalLights[indexx];
        var shadowSetting = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);
        cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(light.visibleLightIndex, 0, 1, Vector3.zero, tileSize, 0f
            , out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData);
        shadowSetting.splitData = splitData;
        buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
        ExecuteBuffer();
        context.DrawShadows(ref shadowSetting);
    }

    public void ReserveDirectionalShadows(Light light, int visibleLightIndex)
    {
        if (shadowedDirectionalLightCount < maxShadowedDirectionalLightCount
        && light.shadows != LightShadows.None && light.shadowStrength > 0f//灯光的阴影模式设置为无或阴影强度为零 不用产生阴影
        && cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))//判断灯光的阴影是否可见
        {
            shadowedDirectionalLights[shadowedDirectionalLightCount++] = new ShadowedDirectionalLight() { visibleLightIndex = visibleLightIndex };
        }
    }



}
