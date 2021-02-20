using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class TBNVisible : MonoBehaviour
{
    [Range(0, 0.5f)] public float lineLength = 0.1f;
    [Range(0, 0.005f)] public float verRadio = 0.001f;
    public bool showNormal;
    public bool showTangent;
    public bool showBiTangent;

    private void OnDrawGizmos()
    {
        MeshFilter filter = GetComponent<MeshFilter>();
        if (filter == null)
            return;
        Mesh mesh = filter.sharedMesh;
        if (mesh)
        {
            ShowTangent(mesh);
        }
    }

    private void ShowTangent(Mesh mesh)
    {
        var vertices = mesh.vertices;
        var normals = mesh.normals;
        var tangents = mesh.tangents;

        for (int i = 0; i < vertices.Length; i++)
        {
            var verWS = transform.TransformPoint(vertices[i]);
            var normalWS = transform.TransformDirection(normals[i]);
            var tangentWS = transform.TransformDirection(tangents[i]);

            //Normal
            if (showNormal)
            {
                Gizmos.color = Color.green;
                Gizmos.DrawLine(verWS, verWS + normalWS * lineLength);
            }

            //tangentWS
            //因为垂直于法线方向的切线有无数条，所以就用了w来确定到底使用哪一条切线
            if (showTangent)
            {
                Gizmos.color = Color.red;
                Gizmos.DrawLine(verWS, verWS + tangentWS * lineLength);
            }

            if (showBiTangent)
            {
                //tangentWS 正确方向
                // Gizmos.color = Color.blue;
                float tangetDir = tangents[i].w;
                // Gizmos.DrawLine(verWS, verWS + tangentWS * lineLength);

                //BiTangent 副切线
                Vector3 biTangentDir = Vector3.Cross(normalWS, tangentWS) * tangetDir;
                Gizmos.color = Color.yellow;
                Gizmos.DrawLine(verWS, verWS + biTangentDir * lineLength);
            }



            Gizmos.color = Color.black;
            Gizmos.DrawSphere(verWS, verRadio);
        }
    }
}
