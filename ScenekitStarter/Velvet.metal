
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
    packed_float4 primaryColor;
    packed_float4 fuzzColor;
    packed_float4 underColor;
    float rolloff;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

/*
    Translated from HLSL shader for VVVV
    vNoiseVelvety.fx
    by Desaxismundi 2008

    Velvet shader originally by NVIDIA

    GLSL conversion toneburst 2008
*/

vertex VertexOut VelvetVertex(VertexIn in [[stage_in]],
                              constant SCNSceneBuffer &scn_frame   [[buffer(0)]],
                              constant NodeConstants &scn_node     [[buffer(1)]],
                              constant LightConstants &light       [[buffer(2)]],
                              constant MaterialConstants &material [[buffer(3)]])

{
    // Transform normal into Eye Space
    float4 Nm = normalize(scn_node.normalTransform * float4(in.normal, 0.0f));
    float3 Nn = Nm.xyz;
    // Transform vertex into Eye Space
    float4 Po = in.position;
    float3 Pe = (scn_node.modelViewTransform * Po).xyz;
    float3 Ln = normalize(light.position - Pe);
    float ldn = dot(Ln, Nn);
    float diffComp = max(0.0f, ldn);
    float3 diffContrib = diffComp * material.primaryColor.rgb;
    float subLamb = smoothstep(-material.rolloff, 1.0f, ldn) - smoothstep(0.0f, 1.0f, ldn);
    subLamb = max(0.0f, subLamb);
    float3 subContrib = subLamb * material.underColor.rgb;
    float3 cameraPos = float3(0.0f, 0.0f, 1.0f);
    float3 Vn = normalize(cameraPos - Pe);
    float vdn = 1.0f -dot(Vn, Nn);
    float3 vecColor = float3(vdn, vdn, vdn);
    float3 diffColor = subContrib + diffContrib;
    float3 specColor = vecColor * material.fuzzColor.rgb;
    float3 surfaceColor = diffColor + specColor;

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.color = float4(surfaceColor, 1.0f);
    return out;
}

fragment float4 VelvetFragment(VertexOut in [[stage_in]])
{
    return in.color;
}
