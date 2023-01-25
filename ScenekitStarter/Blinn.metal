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
    packed_float3 diffuseIntensity;
    packed_float3 ambientIntensity;
    packed_float3 position;
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 lightDir;
};

vertex VertexOut BlinnVertex(VertexIn in [[stage_in]],
                             constant SCNSceneBuffer &scn_frame    [[buffer(0)]],
                             constant NodeConstants &scn_node      [[buffer(1)]],
                             constant LightConstants &vertexLight [[buffer(2)]])
{
    float4 viewPosition = scn_node.modelViewTransform * in.position;
    float3 v = float3(viewPosition.xyz / viewPosition.w);
    float4 n = scn_node.normalTransform * float4(in.normal, 0.0f);
    float3 normal = normalize(n.xyz);

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.normal = normal;
    out.lightDir = float3(vertexLight.position.xyz - v);

    return out;
}

fragment float4 BlinnFragment(VertexOut in [[stage_in]],
                              constant LightConstants &fragmentLight [[buffer(2)]])
{
    const float3 emissionColor(0.0f, 0.0f, 0.0f);
    const float3 ambientColor(1.0f, 1.0f, 1.0f);
    const float3 diffuseColor(1.0f, 1.0f, 1.0f);

    // Ambient contribution
    float3 surfaceColor = emissionColor + ambientColor * fragmentLight.ambientIntensity;
    float3 N = normalize(in.normal);
    float3 L = normalize(in.lightDir);
    float lambertTerm = dot(N,L);
    if(lambertTerm > 0.0) {
        // Diffuse contribution
        surfaceColor += fragmentLight.diffuseIntensity * diffuseColor * lambertTerm;
    }
    return float4(surfaceColor, 1.0f);
}
