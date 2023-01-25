
#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct VertexIn {
    float4 position  [[attribute(SCNVertexSemanticPosition)]];
    float3 normal    [[attribute(SCNVertexSemanticNormal)]];
    float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeConstants {
    float4x4 modelViewTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 normalTransform;
};

struct LightConstants {
    packed_float3 position;
};

struct MaterialConstants {
    packed_float4 diffuseColor;
    packed_float4 specularColor;
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 lightVec;
    float3 halfVec;
};

/*
    Subsurface scattering approximation
    Adapted from GPU Gems Vol.1
    Chapter 16. 'Real-Time Approximations to Subsurface Scattering'
    by Simon Green

    Available online at
    http://http.developer.nvidia.com/GPUGems/gpugems_ch16.html
 */

vertex VertexOut LUTSkinVertex(VertexIn in [[stage_in]],
                               constant SCNSceneBuffer &scn_frame [[buffer(0)]],
                               constant NodeConstants &scn_node   [[buffer(1)]],
                               constant LightConstants &light     [[buffer(2)]])
{
    const float3 eye(0.0f, 0.0f, 1.0f);
    float4 eyeNormal = scn_node.normalTransform * float4(in.normal, 0.0f);

    float4 v = scn_node.modelViewTransform * in.position;
    float3 V = v.xyz / v.w;

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.normal = normalize(eyeNormal.xyz);
    out.lightVec = normalize(light.position.xyz - V.xyz);
    out.halfVec = normalize(out.lightVec + eye);
    return out;
}

fragment float4 LUTSkinFragment(VertexOut in [[stage_in]],
                                texture2d<float, access::sample> skinLUT [[texture(0)]],
                                constant MaterialConstants &material [[buffer(0)]])
{
    constexpr sampler bilinearClampedSampler(coord::normalized,
                                             min_filter::linear,
                                             mag_filter::linear,
                                             mip_filter::none,
                                             address::clamp_to_edge);
    float2 s {
        dot(in.normal, in.lightVec),
        dot(in.normal, in.halfVec)
    };
    s = s * 0.5f + 0.5f;
    s.x = min(0.996f, s.x);
    float4 light = skinLUT.sample(bilinearClampedSampler, s);
    return material.diffuseColor * light + material.specularColor * light.a;
}
