using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeightCamera : MonoBehaviour
{
    private Camera m_Camera;
    // Start is called before the first frame update
    void Start()
    {
        m_Camera = GetComponent<Camera>();
        m_Camera.depthTextureMode = DepthTextureMode.Depth;
        // m_Camera.SetReplacementShader(Shader.Find("XHH/HeightCamera"), "Opaque");
    }

}
