using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ShadowSettings
{
    public enum TextureSize
    {
        _256 = 256,
        _512 = 512,
        _1024 = 1024,
        _2048 = 2048,
        _4096 = 4096,
        _8192 = 8192
    }

    public enum FilterMode
    {
        PCF2x2,
        PCF3x3,
        PCF5x5,
        PCF7x7
    }

    [System.Serializable]
    public struct Directional
    {
        public TextureSize atlasSize;
        public FilterMode filter;
        [Header("Cascaded Shadow Maps Count"), Range(1, 4)] public int cascadeCount;
        // [Header("Cascaded Shadow Maps Rate")
        [Range(0f, 1f)] public float cascadeRatio1, cascadeRatio2, cascadeRatio3;


        public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);
        [Range(0.001f, 1f)]
        public float cascadeFade;
    }

    [Min(0.001f)]
    public float maxDistance = 100f;//阴影最大距离
    [Range(0.001f, 1f)]
    public float distanceFade = 0.1f;//阴影淡入度



    public Directional directional = new Directional()
    {
        atlasSize = TextureSize._1024,
        filter = FilterMode.PCF2x2,
        cascadeCount = 4,
        cascadeRatio1 = 0.1f,
        cascadeRatio2 = 0.25f,
        cascadeRatio3 = 0.5f,
        cascadeFade = 0.1f
    };
}


