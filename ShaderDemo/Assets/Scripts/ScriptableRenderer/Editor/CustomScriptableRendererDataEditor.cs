using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.Rendering;
using UnityEditor.Rendering.Universal;

[CustomEditor(typeof(CustomScriptableRendererData), true)]
public class CustomScriptableRendererDataEditor : ScriptableRendererDataEditor
{
    SerializedProperty m_OpaqueLayerMask;

    private void OnEnable()
    {
        m_OpaqueLayerMask = serializedObject.FindProperty("m_OpaqueLayerMask");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        EditorGUILayout.PropertyField(m_OpaqueLayerMask);
        serializedObject.ApplyModifiedProperties();
        base.OnInspectorGUI();
    }
}
