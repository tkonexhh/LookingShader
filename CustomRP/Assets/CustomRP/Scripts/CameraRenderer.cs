using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class CameraRenderer
{
    private const string bufferName = "Render Camera";

    private CommandBuffer buffer = new CommandBuffer { name = bufferName };

    private ScriptableRenderContext context;
    private Camera camera;

    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;

        Setup();
        DrawVisibleGeometry();
        Submit();

    }

    void DrawVisibleGeometry()
    {
        context.DrawSkybox(camera);
    }

    void Setup()
    {
        buffer.BeginSample(bufferName);
        ExecuteBuffer();
        context.SetupCameraProperties(camera);
    }



    void Submit()
    {
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
}
