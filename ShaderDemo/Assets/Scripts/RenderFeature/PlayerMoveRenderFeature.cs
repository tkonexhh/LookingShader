using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


public class PlayerMoveRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public Material blitMaterial = null;
        //public int blitMaterialPassIndex = -1;
        //目标RenderTexture 
        public string textureName = "";
        public RenderTexture renderTexture = null;

    }
    public Settings settings = new Settings();
    private PlayerMovePass blitPass;

    public override void Create()
    {
        blitPass = new PlayerMovePass(name, settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.blitMaterial == null)
        {
            Debug.LogWarningFormat("丢失blit材质");
            return;
        }
        blitPass.renderPassEvent = settings.renderPassEvent;
        blitPass.Setup(renderer.cameraColorTarget);
        renderer.EnqueuePass(blitPass);
    }
}

public class PlayerMovePass : ScriptableRenderPass
{

    private PlayerMoveRenderFeature.Settings settings;
    string m_ProfilerTag;
    RenderTargetIdentifier source;
    int shaderKey = -1;

    public PlayerMovePass(string tag, PlayerMoveRenderFeature.Settings settings)
    {
        m_ProfilerTag = tag;
        this.settings = settings;
        shaderKey = Shader.PropertyToID(settings.textureName);
    }

    public void Setup(RenderTargetIdentifier src)
    {
        source = src;
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer command = CommandBufferPool.Get(m_ProfilerTag);
        RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;

        // command.GetTemporaryRT(shaderKey, opaqueDesc, FilterMode.Bilinear);
        // command.Blit(source, shaderKey);
        command.Blit(shaderKey, settings.renderTexture, settings.blitMaterial);
        context.ExecuteCommandBuffer(command);
        CommandBufferPool.Release(command);
    }
}
