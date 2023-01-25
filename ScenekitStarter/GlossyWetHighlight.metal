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
    float4x4 inverseProjectionTransform;
};

struct LightConstants {
    packed_float3 position;
    packed_float3 ambientIntensity;
    packed_float3 diffuseIntensity;
    packed_float3 specularIntensity;
};

struct MaterialConstants {
    float specularExponent;
    float specularity;
    float glossMin;
    float glossMax;
    float glossDrop;
};

struct VertexOut {
    float4 position [[position]];
    //float4 color;
    float2 texCoords;
    float3 lightVec;
    float3 eyeView;
    float3 eyeNormal;
};

/*
    Adapted from:
    'glossyWetHilight.fx' from NVIDIA shader library
    http://developer.download.nvidia.com/shaderlibrary/HLSL/glossyWetHilight.fx
    NDVIDIA Corporation 2007

    HLSL > GLSL conversion and Quartz Composer setup
    toneburst 2008
    http://machinesdontcare.wordpress.com
 */

// Main Glossy Wet Hilight Vertex Shader function
void glossyWetVS(VertexIn in, thread VertexOut &out, constant NodeConstants &scn_node, constant LightConstants &light)
{
    out.lightVec = light.position.xyz - in.position.xyz;
    out.eyeView = normalize(scn_node.inverseProjectionTransform[3].xyz - in.position.xyz);
    float4 n = scn_node.normalTransform * float4(in.normal, 0.0f);
    out.eyeNormal = normalize(n.xyz);
}

vertex VertexOut GlossyWetHighlightVertex(VertexIn in [[stage_in]],
                                          constant SCNSceneBuffer &scn_frame    [[buffer(0)]],
                                          constant NodeConstants &scn_node      [[buffer(1)]],
                                          constant LightConstants &vertexLights [[buffer(2)]])
{
    VertexOut out;
    glossyWetVS(in, out, scn_node, vertexLights);

    out.position = scn_node.modelViewProjectionTransform * in.position;
    //out.color = in.color;
    out.texCoords = /*gl_TextureMatrix[0] **/ in.texCoords;

    return out;
}

/*
    Adapted from:
    'glossyWetHilight.fx' from NVIDIA shader library
    http://developer.download.nvidia.com/shaderlibrary/HLSL/glossyWetHilight.fx
    NDVIDIA Corporation 2007

    HLSL > GLSL conversion and Quartz Composer setup
    toneburst 2008
    http://machinesdontcare.wordpress.com
 */

static float3 lit (float NdotL, float NdotH, float m)
{
    float ambient = 1.0;
    float diffuse = max(NdotL, 0.0);
    float specular = step(0.0, NdotL) * max(NdotH * m, 1.0);
    return float3(ambient, diffuse, specular);
}

// Calculates specular dropoff
float glossy_drop(float v, float gMax, float gMin, float gDrop)
{
    return (gDrop + smoothstep(gMin, gMax, v) * (1.0f - gDrop));
}

// Main Glossy Wet Hilight Fragment Shader function
float4 glossyWetFS(thread VertexOut &in, float4 baseColor, constant LightConstants &light, constant MaterialConstants &material)
{
    float3 Ln = normalize(in.lightVec);
    float3 Nn = normalize(in.eyeNormal);
    float3 Vn = normalize(in.eyeView);
    float3 Hn = normalize(Vn + Ln);
    // Specular component
    float4 litV = float4(lit(dot(Ln, Nn), dot(Hn, Nn), material.specularExponent), 1.0);
    float spec = powr(litV.y, litV.z);
    spec *= (material.specularity * glossy_drop(spec, material.glossMax, material.glossMin, material.glossDrop));
    float3 specularContrib = spec * light.specularIntensity.xyz;
    // Diffuse component
    float3 diffuseContrib = litV.y * light.diffuseIntensity.xyz + light.ambientIntensity.xyz;
    // Combine lighting components and output result
    return float4(specularContrib + (baseColor.rgb * diffuseContrib), baseColor.a);
}

fragment float4 GlossyWetHighlightFragment(VertexOut in [[stage_in]],
                                           /*texture2d<float, access::sample> tex2d  [[texture(0)]],*/
                                           constant LightConstants &fragmentLights [[buffer(0)]],
                                           constant MaterialConstants &material    [[buffer(1)]])
{
    /*
    constexpr sampler bilinearClampedSampler(coord::normalized,
                                             min_filter::linear,
                                             mag_filter::linear,
                                             mip_filter::none,
                                             address::clamp_to_edge);

    float4 baseColor = tex2d.sample(bilinearClampedSampler, in.texCoords);
    */
    float4 baseColor(1.0f, 1.0f, 1.0f, 1.0f);
    return glossyWetFS(in, baseColor, fragmentLights, material);
}
