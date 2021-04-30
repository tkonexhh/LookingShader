using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class Blit_Volumetric : Blit
{
    private int m_ShaderPropID_InverseProjectionMatrix;
    private int m_ShaderPropID_InverseViewMatrix;
    protected override void OnCreate()
    {
        m_ShaderPropID_InverseProjectionMatrix = Shader.PropertyToID("_InverseProjectionMatrix");
        m_ShaderPropID_InverseViewMatrix = Shader.PropertyToID("_InverseViewMatrix");
    }


    protected override void OnBeforeEnqueuePass(ref RenderingData renderingData)
    {
        var projectionMatrix = renderingData.cameraData.camera.projectionMatrix;
        Shader.SetGlobalMatrix(m_ShaderPropID_InverseProjectionMatrix, projectionMatrix.inverse);
        Shader.SetGlobalMatrix(m_ShaderPropID_InverseViewMatrix, renderingData.cameraData.camera.cameraToWorldMatrix);
        // Debug.LogError(projectionMatrix);
    }
}
