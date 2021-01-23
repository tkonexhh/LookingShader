using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");
    static int cutoffID = Shader.PropertyToID("_Cutoff");
    static int metallicID = Shader.PropertyToID("_Metallic");
    static int smoothnewwID = Shader.PropertyToID("_Smoothness");

    [SerializeField] Color baseColor = Color.white;
    [SerializeField, Range(0f, 1f)] float cutoff = 0.5f, metallic = 0.5f, smoothness = 0.5f;

    static MaterialPropertyBlock block;

    private void Awake()
    {
        OnValidate();
    }

    private void OnValidate()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
        }

        block.SetColor(baseColorID, baseColor);
        block.SetFloat(cutoffID, cutoff);
        block.SetFloat(metallicID, metallic);
        block.SetFloat(smoothnewwID, smoothness);
        GetComponent<Renderer>().SetPropertyBlock(block);
    }
}
