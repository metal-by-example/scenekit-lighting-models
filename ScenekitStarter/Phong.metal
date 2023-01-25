
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
    packed_float3 diffuseIntensity;
    packed_float3 ambientIntensity;
};

struct MaterialConstants {
    packed_float3 specularColor;
    float shininess;
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
    float3 lightDir;
    float3 eyeVec;
};

vertex VertexOut PhongVertex(VertexIn in [[stage_in]],
                             constant SCNSceneBuffer &scn_frame   [[buffer(0)]],
                             constant NodeConstants &scn_node     [[buffer(1)]],
                             constant LightConstants &vertexLight [[buffer(2)]])
{
    float4 viewPosition = scn_node.modelViewTransform * in.position;
    float3 V = viewPosition.xyz / viewPosition.w;
    float4 N = scn_node.normalTransform * float4(in.normal, 0.0f);

    VertexOut out;
    out.position = scn_node.modelViewProjectionTransform * in.position;
    out.normal = normalize(N.xyz);
    out.lightDir = vertexLight.position.xyz - V;
    out.eyeVec = -V;

    return out;
}

fragment float4 PhongFragment(VertexOut in [[stage_in]],
                              constant LightConstants &fragmentLight [[buffer(2)]],
                              constant MaterialConstants &material   [[buffer(3)]])
{
    float3 specularIntensity(1.0f, 1.0f, 1.0f);

    float3 emissiveIntensity(0.0f, 0.0f, 0.0f);
    float3 ambientColor(1.0f, 1.0f, 1.0f);
    float3 diffuseColor(1.0f, 1.0f, 1.0f);
    float3 specularColor(material.specularColor.rgb);

    // Ambient contribution
    float3 surfaceColor = emissiveIntensity + ambientColor * fragmentLight.ambientIntensity.rgb;

    float3 N = normalize(in.normal);
    float3 L = normalize(in.lightDir);
    float diffuseFactor = saturate(dot(N,L));
    if(diffuseFactor > 0.0)
    {
        // Diffuse contribution
        surfaceColor += fragmentLight.diffuseIntensity.rgb * diffuseColor * diffuseFactor;

        // Specular contribution
        float3 E = normalize(in.eyeVec);
        float3 R = reflect(-L, N);
        float specularFactor = powr(max(dot(R, E), 0.0), material.shininess);
        surfaceColor += specularIntensity * specularColor * specularFactor;
    }

    return float4(surfaceColor, 1.0f);
}
