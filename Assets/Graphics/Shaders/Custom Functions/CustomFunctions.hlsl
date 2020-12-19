TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D(_CameraNormalsTexture);
SAMPLER(sampler_CameraNormalsTexture);
float4 _CameraNormalsTexture_TexelSize;

void Outlines_float(float2 ScreenPosition, float3 BaseColor, float3 OutlineColor, float OutlineThickness, float OutlineNormalMultiplier, float OutlineNormalBias, float OutlineDepthMultiplier, float OutlineDepthBias, out float3 Composite)
{
    // sample distance
    float halfScaleFloor = floor(OutlineThickness * 0.5);
    float halfScaleCeil = ceil(OutlineThickness * 0.5);
    float2 Texel = (1.0) / float2(_CameraNormalsTexture_TexelSize.z, _CameraNormalsTexture_TexelSize.w);

    // offset sample positions
    float2 posSamples[4];
    posSamples[0] = ScreenPosition - float2(Texel.x, Texel.y) * halfScaleFloor;
    posSamples[1] = ScreenPosition + float2(Texel.x, Texel.y) * halfScaleCeil;
    posSamples[2] = ScreenPosition + float2(Texel.x * halfScaleCeil, -Texel.y * halfScaleFloor);
    posSamples[3] = ScreenPosition + float2(-Texel.x * halfScaleFloor, Texel.y * halfScaleCeil);

    // base (center) values
    float Depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, ScreenPosition).r;
    float3 Normal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, ScreenPosition);
    
    float normalDifference = 0;
    float depthDifference = 0;

    for(int i = 0; i < 4 ; i++)
    {
        // normals difference
        float3 normalDelta = Normal - SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, posSamples[i]);
        normalDelta = normalDelta.r + normalDelta.g + normalDelta.b;
        normalDifference = normalDifference + normalDelta;
    
        // depth difference
        depthDifference = depthDifference + Depth - SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, posSamples[i]).r;
    }

    // normal sensitivity
    normalDifference = normalDifference * OutlineNormalMultiplier;
    normalDifference = saturate(normalDifference);
    normalDifference = pow(normalDifference, OutlineNormalBias);
    float NormalOutline = normalDifference;    

    // depth sensitivity
    depthDifference = depthDifference * OutlineDepthMultiplier;
    depthDifference = saturate(depthDifference);
    depthDifference = pow(depthDifference, OutlineDepthBias);
    float DepthOutline = depthDifference;

    float Outline = max(NormalOutline, DepthOutline);

    Composite = lerp(BaseColor, OutlineColor, Outline);
}