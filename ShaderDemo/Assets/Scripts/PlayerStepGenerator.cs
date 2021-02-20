using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class PlayerStepGenerator : MonoBehaviour
{
    [SerializeField] private Transform targetTransform;
    public RenderTexture StepRT;
    private RenderTexture m_TempRT;
    public Material SetpMat;

    private Vector3 lastPlayerPos;

    private CommandBuffer command;

    private void OnEnable()
    {
        m_TempRT = RenderTexture.GetTemporary(StepRT.descriptor);
        command = CommandBufferPool.Get("Step");
    }

    private void OnDisable()
    {
        RenderTexture.ReleaseTemporary(m_TempRT);
        m_TempRT = null;
        CommandBufferPool.Release(command);
    }

    private void Update()
    {
        Shader.SetGlobalVector("_PlayerPos", targetTransform.position);
        //if (Vector3.Distance(transform.position, lastPlayerPos) > 0.001f)
        {
            command.Blit(StepRT, m_TempRT);
            command.Blit(m_TempRT, StepRT, SetpMat);
            lastPlayerPos = targetTransform.position;
        }
    }
}
