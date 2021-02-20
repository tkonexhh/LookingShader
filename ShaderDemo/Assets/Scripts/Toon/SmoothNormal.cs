using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class SmoothNormal : MonoBehaviour
{
    public string NewMeshPath = "Assets/1.asset";
    // Start is called before the first frame update
    void Start()
    {
        Mesh mesh = new Mesh();
        var meshRenderer = GetComponent<SkinnedMeshRenderer>();
        if (meshRenderer != null)
        {
            mesh = meshRenderer.sharedMesh;
        }

        if (mesh.normals.Length <= 0)
        {
            var meshFilter = GetComponent<MeshFilter>();
            if (meshFilter != null)
            {
                mesh = meshFilter.sharedMesh;
            }
        }

        if (mesh.normals.Length <= 0)
            return;

        Vector3[] meshNormals = new Vector3[mesh.normals.Length];

        for (int i = 0; i < meshNormals.Length; i++)
        {
            Vector3 newNormal = Vector3.zero;
            Vector3 currentVertex = mesh.vertices[i];
            for (int j = 0; j < meshNormals.Length; j++)
            {
                //如果顶点序号相同
                if (mesh.vertices[j] == currentVertex)
                {
                    newNormal += meshNormals[j];
                }
            }
            newNormal.Normalize();
            meshNormals[i] = newNormal;
        }

        //TBN
        for (int i = 0; i < meshNormals.Length; i++)
        {
            Vector3[] TBN = new Vector3[3];
            TBN[0] = new Vector3(mesh.tangents[i].x, mesh.tangents[i].y, mesh.tangents[i].z);
            TBN[1] = Vector3.Cross(meshNormals[i], mesh.tangents[i]) * mesh.tangents[i].w;
            TBN[2] = meshNormals[i];

            Vector3 tNormal = Vector3.zero;
            tNormal.x = Vector3.Dot(TBN[0], meshNormals[i]);
            tNormal.y = Vector3.Dot(TBN[1], meshNormals[i]);
            tNormal.z = Vector3.Dot(TBN[2], meshNormals[i]);
            meshNormals[i] = tNormal;
        }

        //存入顶点色
        Color[] meshColors = new Color[mesh.colors.Length];
        for (int i = 0; i < meshColors.Length; i++)
        {
            meshColors[i].r = meshNormals[i].x * 0.5f + 0.5f;
            meshColors[i].g = meshNormals[i].y * 0.5f + 0.5f;
            meshColors[i].b = meshNormals[i].z * 0.5f + 0.5f;
            meshColors[i].a = mesh.colors[i].a;
        }

        //新建一个mesh，将之前mesh的所有信息copy过去
        Mesh newMesh = new Mesh();
        newMesh.vertices = mesh.vertices;
        newMesh.triangles = mesh.triangles;
        newMesh.normals = mesh.normals;
        newMesh.tangents = mesh.tangents;
        newMesh.uv = mesh.uv;
        newMesh.uv2 = mesh.uv2;
        newMesh.uv3 = mesh.uv3;
        newMesh.uv4 = mesh.uv4;
        newMesh.uv5 = mesh.uv5;
        newMesh.uv6 = mesh.uv6;
        newMesh.uv7 = mesh.uv7;
        newMesh.uv8 = mesh.uv8;
        //将新模型的颜色赋值为计算好的颜色
        newMesh.colors = meshColors;
        newMesh.colors32 = mesh.colors32;
        newMesh.bounds = mesh.bounds;
        newMesh.indexFormat = mesh.indexFormat;
        newMesh.bindposes = mesh.bindposes;
        newMesh.boneWeights = mesh.boneWeights;
        //将新mesh保存为.asset文件，路径可以是"Assets/Character/Shader/VertexColorTest/TestMesh2.asset"                          
        AssetDatabase.CreateAsset(newMesh, NewMeshPath);
        AssetDatabase.SaveAssets();
        Debug.Log("Done");
    }


}
