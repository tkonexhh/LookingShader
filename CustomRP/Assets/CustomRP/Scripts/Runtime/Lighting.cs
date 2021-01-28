using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Collections;
using UnityEngine.Rendering;

public class Lighting
{
    const string bufferName = "Lighting";

    CommandBuffer buffer = new CommandBuffer() { name = bufferName };

    // static int dirLightCololID = Shader.PropertyToID("_DirectionalLightColor");
    // static int dirLightDirID = Shader.PropertyToID("_DirectionalLightDir");
    CullingResults cullingResults;

    const int maxDirLightCount = 4;
    static int dirLightCountID = Shader.PropertyToID("_DirectionalLightCount");
    static int dirLightColorsID = Shader.PropertyToID("_DirectionalLightColors");
    static int dirLightDirsID = Shader.PropertyToID("_DirectionalLightDirs");

    static Vector4[] dirLightColors = new Vector4[maxDirLightCount];
    static Vector4[] dirLightDirs = new Vector4[maxDirLightCount];

    Shadows shadows = new Shadows();

    public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
    {
        this.cullingResults = cullingResults;
        buffer.BeginSample(bufferName);
        shadows.Setup(context, cullingResults, shadowSettings);
        SetupLights();
        shadows.Render();
        buffer.EndSample(bufferName);
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    void SetupLights()
    {
        int dirLightCount = 0;
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            var visibleLight = visibleLights[i];
            if (visibleLight.lightType == LightType.Directional)//只支持方向光
            {
                SetupDirectionalLight(dirLightCount++, ref visibleLight);
                if (dirLightCount >= maxDirLightCount)//最大支持maxDirLightCount 当灯光数量大于这个值时，终止循环
                    break;
            }
        }

        buffer.SetGlobalInt(dirLightCountID, visibleLights.Length);
        buffer.SetGlobalVectorArray(dirLightColorsID, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirsID, dirLightDirs);
    }

    void SetupDirectionalLight(int index, ref VisibleLight visibleLight)
    {
        /*
        将索引和VisibleLight参数添加到SetupDirectionalLight。用提供的索引设置颜色和方向元素。
        在这种情况下，最终颜色是通过VisibleLight.finalColor属性提供的。
        可以通过VisibleLight.localToWorldMatrix属性找到前向矢量。它是矩阵的第三列，必须再次取反。
        */
        dirLightColors[index] = visibleLight.finalColor;
        dirLightDirs[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        shadows.ReserveDirectionalShadows(visibleLight.light, index);
    }

    public void CleanUp()
    {
        shadows.CleanUp();
    }
}
