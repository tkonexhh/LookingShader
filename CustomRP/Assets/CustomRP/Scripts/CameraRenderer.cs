using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{
    // private const string bufferName = "Render Camera";
    private CommandBuffer buffer = new CommandBuffer();// { name = bufferName };

    private ScriptableRenderContext context;
    private Camera camera;

    CullingResults cullingResults;

    static ShaderTagId unlitShaderTagID = new ShaderTagId("SRPDefaultUnlit");

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;

        PrepareBuffer();
        PrepareForSceneWindow();
        if (!Cull())
            return;

        Setup();
        DrawVisibleGeometry();
        DrawUnsupportedShaders();
        DrawGizmos();
        Submit();

    }

    void DrawVisibleGeometry()
    {
        var sortingSettings = new SortingSettings(camera) { criteria = SortingCriteria.CommonOpaque };
        var drawingSettings = new DrawingSettings(unlitShaderTagID, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        //绘制不透明物体
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox(camera);

        //  绘制透明物体
        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }


    void Setup()
    {
        context.SetupCameraProperties(camera);
        // buffer.ClearRenderTarget(true, true, Color.clear);
        CameraClearFlags flags = camera.clearFlags;
        ///需要清除深度缓冲和颜色缓冲区
        buffer.ClearRenderTarget(
            flags <= CameraClearFlags.Depth,
            flags <= CameraClearFlags.Color,
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);
        buffer.BeginSample(SampleName);
        ExecuteBuffer();

    }

    void Submit()
    {
        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    /// <summary>
    /// 剔除
    /// </summary>
    bool Cull()
    {
        ScriptableCullingParameters parameters;
        if (camera.TryGetCullingParameters(out parameters))
        {
            cullingResults = context.Cull(ref parameters);
            return true;
        }

        return false;
    }
}
