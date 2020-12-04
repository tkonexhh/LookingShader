float remap(float target, float oldMin, float oldMax, float newMin, float newMax)
{
    return(target - oldMin) / (oldMax - oldMin) * (newMax - newMin) + newMin;
}

float2 remap(float2 target, float oldMin, float oldMax, float newMin, float newMax)
{
    target.x = remap(target.x, oldMin, oldMax, newMin, newMax);
    target.y = remap(target.y, oldMin, oldMax, newMin, newMax);
    return target;//(target-oldMin)/(oldMax-oldMin)*(newMax-newMin)+newMin;
}