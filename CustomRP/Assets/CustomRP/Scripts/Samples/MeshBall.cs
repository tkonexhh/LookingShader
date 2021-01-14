using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshBall : MonoBehaviour
{
    static int baseColorID = Shader.PropertyToID("_BaseColor");

    [SerializeField] Mesh mesh = default;
    [SerializeField] Material material = default;

    Matrix4x4[] matrixes = new Matrix4x4[1023];
    Vector4[] baseColors = new Vector4[1023];
    MaterialPropertyBlock block;


    private void Awake()
    {

        for (int i = 0; i < matrixes.Length; i++)
        {
            matrixes[i] = Matrix4x4.TRS(Random.insideUnitSphere * 10f,
                Quaternion.Euler(Random.value * 360f, Random.value * 360f, Random.value * 360f),
                Vector3.one * Random.Range(0.5f, 1.5f));
            baseColors[i] = new Vector4(Random.value, Random.value, Random.value, Random.Range(0.5f, 1f));
        }
    }

    private void Update()
    {
        if (block == null)
        {
            block = new MaterialPropertyBlock();
            block.SetVectorArray(baseColorID, baseColors);
        }

        Graphics.DrawMeshInstanced(mesh, 0, material, matrixes, 1023, block);
    }

}
