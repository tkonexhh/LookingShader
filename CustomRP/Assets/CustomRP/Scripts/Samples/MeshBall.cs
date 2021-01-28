using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshBall : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");
    static int metallicID = Shader.PropertyToID("_Metallic");
    static int smoothnessID = Shader.PropertyToID("_Smoothness");

    [SerializeField] Mesh mesh = default;
    [SerializeField] Material material = default;

    Matrix4x4[] matrixes = new Matrix4x4[1023];
    Vector4[] baseColors = new Vector4[1023];
    float[] metallic = new float[1023];
    float[] smoothness = new float[1023];

    MaterialPropertyBlock block;


    private void Awake()
    {

        for (int i = 0; i < matrixes.Length; i++)
        {
            matrixes[i] = Matrix4x4.TRS(Random.insideUnitSphere * 10f,
                Quaternion.Euler(Random.value * 360f, Random.value * 360f, Random.value * 360f),
                Vector3.one * Random.Range(0.5f, 1.5f));
            baseColors[i] = new Vector4(Random.value, Random.value, Random.value, Random.Range(0.5f, 1f));
            metallic[i] = Random.value < 0.25f ? 1f : 0f;
            smoothness[i] = Random.Range(0.05f, 0.95f);
        }
    }

    private void Update()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
            block.SetVectorArray(baseColorID, baseColors);
            block.SetFloatArray(metallicID, metallic);
            block.SetFloatArray(smoothnessID, smoothness);
        }

        Graphics.DrawMeshInstanced(mesh, 0, material, matrixes, 1023, block);
    }

}
