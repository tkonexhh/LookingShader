using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.Universal.Internal;

public class CustomScriptableRenderer : ScriptableRenderer
{
    DepthOnlyPass m_DepthPrepass;
    RenderTargetHandle m_DepthTexture;
    public CustomScriptableRenderer(CustomScriptableRendererData data) : base(data)
    {
        m_DepthTexture.Init("_CameraDepthTexture");
        m_DepthPrepass = new DepthOnlyPass(RenderPassEvent.BeforeRenderingPrepasses, RenderQueueRange.opaque, data.opaqueLayerMask);
    }

    public override void Setup(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        Camera camera = renderingData.cameraData.camera;
        ref CameraData cameraData = ref renderingData.cameraData;
        RenderTextureDescriptor cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;

        m_DepthPrepass.Setup(cameraTargetDescriptor, m_DepthTexture);
        EnqueuePass(m_DepthPrepass);

        for (int i = 0; i < rendererFeatures.Count; ++i)
        {
            if (rendererFeatures[i].isActive)
                rendererFeatures[i].AddRenderPasses(this, ref renderingData);
        }
    }
}
