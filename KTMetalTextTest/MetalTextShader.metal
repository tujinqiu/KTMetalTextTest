//
//  Shader.metal
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/4.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#include <metal_stdlib>
#include "MetalTextHeader.h"
using namespace metal;

typedef struct {
    float3 position [[attribute(0)]];
    float3 normal   [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
}MetalVertexIn;

typedef struct {
    float4 position [[position]];
    float3 eyeNormal;
    float2 texCoord;
}MetalVertexOut;

vertex MetalVertexOut vertex_func(constant MetalUniforms &uniforms [[ buffer(MetalBufferIndexUniforms) ]],
                                  MetalVertexIn vertexIn [[ stage_in ]])
{
    MetalVertexOut out;
    float4 position = float4(vertexIn.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.eyeNormal = (uniforms.modelViewMatrix * float4(vertexIn.normal, 0)).xyz;
    out.texCoord = vertexIn.texCoord;
    
    return out;
}

fragment half4 fragment_func(MetalVertexOut input [[ stage_in ]],
                             texture2d<half, access::sample> texture [[texture(MetalFragmentTextureIndex)]])
{
    constexpr sampler linearSampler(filter::linear);
    half4 baseColor = texture.sample(linearSampler, input.texCoord);
    float3 L = normalize(float3(0, 0, 1)); // light direction in view space
    float3 N = normalize(input.eyeNormal);
    half diffuse = saturate(dot(N, L));
    half3 color = diffuse * baseColor.rgb;
    return half4(color, baseColor.a);
}
