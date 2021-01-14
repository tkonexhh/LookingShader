using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{
    const string bufferName = "Lighting";

    CommandBuffer buffer = new CommandBuffer() { name = bufferName };

    static int dirLightCololID = Shader.PropertyToID("_DirectionalLightColor");
    static int dirLightDirID = Shader.PropertyToID("_DirectionalLightDir");

    CullingResults cullingResults;

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults)
    {
        this.cullingResults = cullingResults;
        buffer.BeginSample(bufferName);
        SetupLight();
        buffer.EndSample(bufferName);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void SetupLight()
    {
        Light light = RenderSettings.sun;
        buffer.SetGlobalVector(dirLightCololID, light.color.linear * light.intensity);
        buffer.SetGlobalVector(dirLightDirID, -light.transform.forward);
    }
}
