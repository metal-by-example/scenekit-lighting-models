
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
    float filmDepth;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
    float3 diffColor;
    float3 specColor;
    float2 viewDepth;
};

/*
    Extracted and adapted from NVIDIA 'Thinfilm' demo
    ftp://download.nvidia.com/developer/SDK/Individual_Samples/3dgraphics_samples.html
 */

vertex VertexOut ThinFilmVertex(VertexIn in [[stage_in]],
                                constant SCNSceneBuffer &scn_frame   [[buffer(0)]],
                                constant NodeConstants &scn_node     [[buffer(1)]],
                                constant LightConstants &light       [[buffer(2)]],
                                constant MaterialConstants &vertexMaterial [[buffer(3)]])
{
    // Transform normal from model-space to view-space
    float4 n = scn_node.normalTransform * float4(in.normal, 0.0f);
    float3 normalVec = normalize(n.xyz);

    // Compute the eye->vertex vector
    const float3 eyeVector = float3(0.0f, 0.0f, 1.0f);
    float3 eyeVec = eyeVector; // Assume infinite viewer
    float3 lightVec = normalize(light.position);

    // Calculate half-angle vector
    float3 halfAngleVec = normalize(lightVec + eyeVec);

    // Calculate diffuse component
    float diffuse = max(dot(normalVec, lightVec), 0.0f);

    // Calculate specular component
    float specular = max(dot(normalVec, halfAngleVec), 0.0f);
    specular = powr(specular, 32.0f);

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.texCoords = in.texCoords;

    // Compute the view depth for the thin film
    out.viewDepth = float2((1.0f / dot(normalVec, eyeVec)) * vertexMaterial.filmDepth);

    // Output final lighting results
    out.diffColor = diffuse;
    out.specColor = specular;

    return out;
}

fragment float4 ThinFilmFragment(VertexOut in [[stage_in]],
                                 constant MaterialConstants &fragmentMaterial [[buffer(0)]],
                                 /*texture2d<float, access::sample> diffuseMap [[texture(0)]],*/
                                 texture2d<float, access::sample> fringeMap [[texture(1)]])
{
      constexpr sampler bilinearClampedSampler(coord::normalized,
                                               min_filter::linear,
                                               mag_filter::linear,
                                               mip_filter::none,
                                               address::clamp_to_edge);

    // Diffuse material color
    //float3 diffMaterial = diffuseMap.sample(bilinearClampedSampler, in.texCoords).rgb;
    float3 diffMaterial = fragmentMaterial.diffuseColor.rgb;

    // Lookup fringe value based on view depth
    float3 fringeColor = fringeMap.sample(bilinearClampedSampler, in.viewDepth).rgb;

    // modulate specular lighting by fringe color, combine with regular lighting
    return float4(in.diffColor * diffMaterial + fringeColor * in.specColor, 1.0f);
}
