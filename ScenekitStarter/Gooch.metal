
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
    packed_float4 surfaceColor;
    packed_float4 warmColor;
    packed_float4 coolColor;
    float diffuseWarm;
    float diffuseCool;
};

struct VertexOut {
    float4 position [[position]];
    float3 reflectVec;
    float3 viewVec;
    float NdotL;
};

vertex VertexOut GoochVertex(VertexIn in [[stage_in]],
                             constant SCNSceneBuffer &scn_frame [[buffer(0)]],
                             constant NodeConstants &scn_node   [[buffer(1)]],
                             constant LightConstants &light     [[buffer(2)]])
{
    float4 eyePosition = scn_node.modelViewTransform * in.position;
    float3 v = eyePosition.xyz / eyePosition.w;
    float4 n = scn_node.normalTransform * float4(in.normal, 0.0f);
    float3 tnorm = normalize(n.xyz);
    float3 lightVec = normalize(light.position - v);

    VertexOut out;
    out.reflectVec = normalize(reflect(-lightVec, tnorm));
    out.viewVec = normalize(-v);
    out.NdotL = (dot(lightVec, tnorm) + 1.0f) * 0.5f;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    return out;
}

fragment float4 GoochFragment(VertexOut in [[stage_in]],
                              constant MaterialConstants &material [[buffer(0)]])
{
    float3 kcool = min(material.coolColor.rgb + material.diffuseCool * material.surfaceColor.rgb, 1.0f);
    float3 kwarm = min(material.warmColor.rgb + material.diffuseWarm * material.surfaceColor.rgb, 1.0f);
    float3 kfinal = mix(kcool, kwarm, in.NdotL);

    float3 nreflect = normalize(in.reflectVec);
    float3 nview = normalize(in.viewVec);

    float spec = max(dot(nreflect, nview), 0.0f);
    spec = powr(spec, 32.0f);

    return float4(min(kfinal + spec, 1.0), 1.0);
}
