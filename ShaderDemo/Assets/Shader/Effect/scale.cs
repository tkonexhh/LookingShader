using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class scale : MonoBehaviour
{
    [SerializeField] private Renderer m_Renderer;

    private Material m_Mat;
    void Start()
    {
        m_Mat = m_Renderer.material;
    }

    // Update is called once per frame
    void Update()
    {
        m_Mat.SetFloat("_ScaleX", transform.localScale.x);
        m_Mat.SetFloat("_ScaleY", transform.localScale.z);
    }
}
