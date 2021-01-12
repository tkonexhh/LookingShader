using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class HeightCamera : MonoBehaviour
{
    private Camera m_Camera;
    public RenderTexture stepRT;
    public RenderTexture mTmpRT;
    public Material setpMat;

    private void OnEnable()
    {
        mTmpRT = RenderTexture.GetTemporary(stepRT.descriptor);
    }

    void Start()
    {
        m_Camera = GetComponent<Camera>();
        m_Camera.depthTextureMode = DepthTextureMode.Depth;
        // m_Camera.SetReplacementShader(Shader.Find("XHH/HeightCamera"), "Opaque");
    }

    // private void Update()
    // {
    //     Graphics.Blit(stepRT, mTmpRT);
    //     // Graphics.Blit(mTmpRT, stepRT, setpMat, 0);
    // }
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Debug.LogError(111);
        Graphics.Blit(src, stepRT);
        // Graphics.
    }

}
