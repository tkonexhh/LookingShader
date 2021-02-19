using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
#endif
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable]
public class CustomScriptableRendererData : ScriptableRendererData
{

#if UNITY_EDITOR
    [MenuItem("Assets/Create/Rendering/Create Custom Renderer", priority = CoreUtils.assetCreateMenuPriority2)]
    static void CreateForwardRendererData()
    {
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreateCustomRendererAsset>(), "CustomRenderer.asset", null, null);
    }

    internal class CreateCustomRendererAsset : EndNameEditAction
    {
        public override void Action(int instanceId, string pathName, string resourceFile)
        {
            var instance = CreateInstance<CustomScriptableRendererData>();
            AssetDatabase.CreateAsset(instance, pathName);
            ResourceReloader.ReloadAllNullIn(instance, UniversalRenderPipelineAsset.packagePath);
            Selection.activeObject = instance;
        }
    }
#endif

    [SerializeField] LayerMask m_OpaqueLayerMask = -1;

    /// <summary>
    /// Use this to configure how to filter opaque objects.
    /// </summary>
    public LayerMask opaqueLayerMask
    {
        get => m_OpaqueLayerMask;
        set
        {
            SetDirty();
            m_OpaqueLayerMask = value;
        }
    }

    protected override ScriptableRenderer Create()
    {
        return new CustomScriptableRenderer(this);
    }
}
