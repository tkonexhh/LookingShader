using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Blit : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;

        public Material blitMaterial = null;
        public int blitMaterialPassIndex = -1;
        public Target destination = Target.Color;
        public string textureId = "_BlitPassTexture";
    }

    public enum Target
    {
        Color,
        Texture
    }

    public Settings settings = new Settings();
    RenderTargetHandle m_RenderTextureHandle;

    BlitPass blitPass;

    public override void Create()
    {
        var passIndex = settings.blitMaterial != null ? settings.blitMaterial.passCount - 1 : 1;
        settings.blitMaterialPassIndex = Mathf.Clamp(settings.blitMaterialPassIndex, -1, passIndex);
        blitPass = new BlitPass(settings.Event, settings.blitMaterial, settings.blitMaterialPassIndex, name);
        m_RenderTextureHandle.Init(settings.textureId);
        OnCreate();
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var src = renderer.cameraColorTarget;
        var dest = (settings.destination == Target.Color) ? RenderTargetHandle.CameraTarget : m_RenderTextureHandle;

        if (settings.blitMaterial == null)
        {
            Debug.LogWarningFormat("Missing Blit Material. {0} blit pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
            return;
        }

        blitPass.Setup(src, dest);
        OnBeforeEnqueuePass(ref renderingData);
        renderer.EnqueuePass(blitPass);
    }

    protected virtual void OnCreate() { }
    protected virtual void OnBeforeEnqueuePass(ref RenderingData renderingData) { }

}


class BlitPass : ScriptableRenderPass
{
    public Material blitMaterial = null;
    public int blitShaderPassIndex = 0;
    public FilterMode filterMode { get; set; }

    private RenderTargetIdentifier source { get; set; }
    private RenderTargetHandle destination { get; set; }

    RenderTargetHandle m_TemporaryColorTexture;
    string m_ProfilerTag;

    /// <summary>
    /// Create the CopyColorPass
    /// </summary>
    public BlitPass(RenderPassEvent renderPassEvent, Material blitMaterial, int blitShaderPassIndex, string tag)
    {
        this.renderPassEvent = renderPassEvent;
        this.blitMaterial = blitMaterial;
        this.blitShaderPassIndex = blitShaderPassIndex;
        m_ProfilerTag = tag;
        m_TemporaryColorTexture.Init("_TemporaryColorTexture");
    }

    /// <summary>
    /// Configure the pass with the source and destination to execute on.
    /// </summary>
    /// <param name="source">Source Render Target</param>
    /// <param name="destination">Destination Render Target</param>
    public void Setup(RenderTargetIdentifier source, RenderTargetHandle destination)
    {
        this.source = source;
        this.destination = destination;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);

        RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
        opaqueDesc.depthBufferBits = 0;
        opaqueDesc.msaaSamples = 1;

        // Can't read and write to same color target, create a temp render target to blit. 
        if (destination == RenderTargetHandle.CameraTarget)
        {
            cmd.GetTemporaryRT(m_TemporaryColorTexture.id, opaqueDesc, filterMode);
            Blit(cmd, source, m_TemporaryColorTexture.Identifier(), blitMaterial, blitShaderPassIndex);
            Blit(cmd, m_TemporaryColorTexture.Identifier(), source);
        }
        else
        {
            Blit(cmd, source, destination.Identifier(), blitMaterial, blitShaderPassIndex);
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (destination == RenderTargetHandle.CameraTarget)
        {
            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }
    }
}