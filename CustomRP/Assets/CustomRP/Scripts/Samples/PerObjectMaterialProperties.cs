using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");
    static int cutoffID = Shader.PropertyToID("_Cutoff");

    [SerializeField] Color baseColor = Color.white;
    [SerializeField, Range(0f, 1f)] float cutoff = 0.5f;

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
        GetComponent<Renderer>().SetPropertyBlock(block);
    }
}
