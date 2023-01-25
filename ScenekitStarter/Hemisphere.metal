
#include <metal_stdlib>
using namespace metal;

#include <SceneKit/scn_metal>

struct VertexIn {
    float4 position  [[attribute(SCNVertexSemanticPosition)]];
    float3 normal    [[attribute(SCNVertexSemanticNormal)]];
    //float2 texCoords [[attribute(SCNVertexSemanticTexcoord0)]];
};

struct NodeConstants {
    float4x4 modelViewTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 normalTransform;
};

struct LightConstants {
    packed_float3 position;
    packed_float3 skyColor;
    packed_float3 groundColor;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

/*
    From the GLSL Orange Book
    Randi J. Rost
*/

vertex VertexOut HemisphereVertex(VertexIn in [[stage_in]],
                                  constant SCNSceneBuffer &scn_frame [[buffer(0)]],
                                  constant NodeConstants &scn_node   [[buffer(1)]],
                                  constant LightConstants &light     [[buffer(2)]])
{
    float4 Nm = scn_node.normalTransform * float4(in.normal, 0.0f);
    float3 N = normalize(Nm.xyz);
    float3 V = (scn_node.modelViewTransform * in.position).xyz;
    float3 lightVec = normalize(light.position.xyz - V);
    float costheta = dot(N, lightVec);
    float a = 0.5 + 0.5 * costheta;
    float3 litColor = mix(light.groundColor, light.skyColor, a);

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.color = float4(litColor, 1.0f);
    return out;
}

fragment float4 HemisphereFragment(VertexOut in [[stage_in]])
{
    return in.color;
}
