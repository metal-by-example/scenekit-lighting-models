
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
    packed_float3 ambientIntensity;
    packed_float3 diffuseIntensity;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 texCoords;
};

/*
    Adapted from:
    /Developer/Examples/Quartz Composer/Compositions/GLSL/Environment Map.qtz
    More environment maps can be found here
    http://www.codemonsters.de/home/content.php?show=spheremaps
 */

void envMapVS(VertexIn in, thread VertexOut &out, constant NodeConstants &scn_node, constant LightConstants &light)
{
    // (@warrenm) In spite of the naming of the variables below, they are mostly in eye space.
    // I have left the original names for posterity, but there is some confusion in this code
    // about which space we're in.

    float4 vWorld = scn_node.modelViewTransform * in.position;
    float4 Nm = normalize(scn_node.normalTransform * float4(in.normal, 0.0f));
    float3 nWorld = Nm.xyz;

    // Diffuse
    float3 vertToLight = normalize(light.position - vWorld.xyz);
    float diffuseLight = max(dot(vertToLight, nWorld), 0.0);
    out.color = float4(light.ambientIntensity.rgb + (diffuseLight * light.diffuseIntensity.xyz), 1.0f);

    // Environment mapping texture coordinates
    float3 vWorldUnit = normalize(vWorld.xyz);
    float3 f = reflect(vWorldUnit, nWorld);
    float m = 2.0 * sqrt(f.x * f.x + f.y * f.y + (f.z + 1.0) * (f.z + 1.0));
    out.texCoords = float2(f.x / m + 0.5, -f.y / m + 0.5);
}

vertex VertexOut EnvMapVertex(VertexIn in [[stage_in]],
                              constant SCNSceneBuffer &scn_frame    [[buffer(0)]],
                              constant NodeConstants &scn_node      [[buffer(1)]],
                              constant LightConstants &vertexLights [[buffer(2)]])
{
    VertexOut out;
    envMapVS(in, out, scn_node, vertexLights);

    out.position = scn_node.modelViewProjectionTransform * in.position;

    return out;
}

/*
    Adapted from:
    /Developer/Examples/Quartz Composer/Compositions/GLSL/Environment Map.qtz
 */

fragment float4 EnvMapFragment(VertexOut in [[stage_in]],
                               texture2d<float, access::sample> environmentMap [[texture(0)]],
                               constant float &ratio [[buffer(0)]])
{
    constexpr sampler bilinearClampedSampler(coord::normalized,
                                             min_filter::linear,
                                             mag_filter::linear,
                                             mip_filter::none,
                                             address::clamp_to_edge);
    float2 tex = in.texCoords;
    tex.y = 1.0f - tex.y;
    float4 environmentColor = environmentMap.sample(bilinearClampedSampler, tex);
    float4 finalColor = mix(in.color, environmentColor, ratio);
    return finalColor;
}
