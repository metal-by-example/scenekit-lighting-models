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

struct MaterialConstants {
    packed_float4 edgeColor;
    packed_float4 surfaceColor;
    float specularity;
    float fuzziness;
    float edgeFade;
};

struct VertexOut {
    float4 position [[position]];
    float3 lightVec;
    float3 eyeView;
    float3 eyeNormal;
};

/////////////////////////////////////
////         EDGE FUZZ VS        ////
/////////////////////////////////////

/*
    Adapted from:
    NVIDIA Shader Library effect 'EdgeFuzz.fx'
    http://developer.download.nvidia.com/shaderlibrary/webpages/shader_library.html
 */

// Edge Fuzz Vertex Shader function
void edgefuzzVS(constant NodeConstants &scn_node, float4 modelPosition, float4 N, float3 lightPosition, thread VertexOut &out)
{
    float4 V = scn_node.modelViewTransform * modelPosition;
    float3 v = V.xyz / V.w;
    out.lightVec = lightPosition - v.xyz;
    out.eyeView = normalize(float3(0.0, 0.0, 2.0) - v.xyz);
    float4 n = scn_node.normalTransform * N;
    out.eyeNormal = normalize(n.xyz);
}

vertex VertexOut EdgeFuzzVertex(VertexIn in [[stage_in]],
                                constant SCNSceneBuffer &scn_frame    [[buffer(0)]],
                                constant NodeConstants &scn_node      [[buffer(1)]],
                                constant LightConstants &vertexLights [[buffer(2)]])
{
    float4 n = float4(in.normal, 0.0f);

    VertexOut out;
    edgefuzzVS(scn_node, in.position, n, vertexLights.position, out);

    out.position = scn_node.modelViewProjectionTransform * in.position;

    return out;
}

/////////////////////////////////////
////         EDGE FUZZ FS        ////
/////////////////////////////////////

/*
    Adapted from:
    NVIDIA Shader Library effect 'EdgeFuzz.fx'
 */

float3 lit (float NdotL, float NdotH, float m)
{
    float ambient = 1.0;
    float diffuse = max(NdotL, 0.0);
    float specular = step(0.0, NdotL) * max(NdotH * m, 1.0);
    return float3(ambient, diffuse, specular);
}

// Edge Fuzz Fragment Shader function
float4 edgefuzzFS(VertexOut vert, constant LightConstants &light, constant MaterialConstants &material)
{
    const float4 specularColor = float4(1.0, 1.0, 1.0, 1.0);
    float3 Ln = normalize(vert.lightVec);
    float3 Vn = normalize(vert.eyeView);
    float3 Nn = normalize(vert.eyeNormal);
    float3 Hn = normalize(Vn + Ln);
    float ldn = dot(Ln, Nn);
    float4 lv = float4(lit(ldn, dot(Hn, Nn), material.specularity), 1.0);
    float subd = abs(dot(Nn, Vn));
    subd = powr(subd, material.fuzziness);
    float3 surfColor = mix(material.edgeColor.rgb, material.surfaceColor.rgb, subd);
    surfColor = mix(material.surfaceColor.rgb, surfColor, material.edgeFade);
    ldn = max(ldn,0.0);
    ldn = powr(ldn, material.fuzziness);
    float3 incidentColor = mix(material.edgeColor.rgb, light.diffuseIntensity.rgb, ldn);
    incidentColor = mix(light.diffuseIntensity.rgb, incidentColor, ldn);
    float3 diffContrib = surfColor * (lv.y * incidentColor + light.ambientIntensity.rgb);
    float3 specContrib = specularColor.rgb * lv.y * lv.z * incidentColor;

    return float4(diffContrib + specContrib, 1.0);
}

fragment float4 EdgeFuzzFragment(VertexOut in [[stage_in]],
                                 constant LightConstants &fragmentLights [[buffer(0)]],
                                 constant MaterialConstants &material [[buffer(1)]])
{
    return edgefuzzFS(in, fragmentLights, material);
}
