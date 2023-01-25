
#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct VertexIn {
    float4 position  [[attribute(SCNVertexSemanticPosition)]];
    float3 normal    [[attribute(SCNVertexSemanticNormal)]];
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
    packed_float3 ambientColor;
    packed_float3 diffuseColor;
    packed_float3 subColor;
    float rolloff;
};

struct VertexOut {
    float4 position [[position]];
    float3 lightVec;
    float3 eyeNormal;
};

/*
    Adapted from:
    'lambSkin' shader from NVIDIA shader library
    http://developer.download.nvidia.com/shaderlibrary/webpages/shader_library.html

    "A lambertian-like surface with light 'bleed-through'."
*/

vertex VertexOut LambSkinVertex(VertexIn in [[stage_in]],
                                constant SCNSceneBuffer &scn_frame [[buffer(0)]],
                                constant NodeConstants &scn_node   [[buffer(1)]],
                                constant LightConstants &light     [[buffer(2)]])
{
    VertexOut out;

    float4 V = scn_node.modelViewTransform * in.position;
    float4 N = normalize(scn_node.normalTransform * float4(in.normal, 0.0f));

    out.lightVec = light.position - V.xyz;
    out.eyeNormal = N.xyz;

    out.position = scn_node.modelViewProjectionTransform * in.position;
    return out;
}

fragment float4 LambSkinFragment(VertexOut in [[stage_in]],
                                 constant MaterialConstants &material [[buffer(0)]])
{
    // Normalize normal and light vector
    float3 Ln = normalize(in.lightVec);
    float3 Nn = normalize(in.eyeNormal);

    float ldn = dot(Ln, Nn);

    // Calculate diffuse contribution
    float diffComp = max(0.0f, ldn);
    float3 diffuse = (diffComp * material.diffuseColor).xyz;

    // Calculate simulated subsurface contribution
    float subLamb = smoothstep(-material.rolloff, 1.0f, ldn) - smoothstep(0.0f, 1.0f, ldn);
    subLamb = max(0.0f, subLamb);
    float3 subsurface = subLamb * material.subColor.xyz;

    float3 surfaceColor = material.ambientColor.xyz + diffuse + subsurface;
    return float4(surfaceColor, 1.0f);
}
