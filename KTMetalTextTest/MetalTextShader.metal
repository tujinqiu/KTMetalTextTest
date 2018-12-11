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
    float2 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
}MetalVertexIn;

typedef struct {
    float4 position [[position]];
    float4 color;
}MetalVertexOut;

vertex MetalVertexOut vertex_func(constant MetalUniforms &uniforms [[ buffer(MetalBufferIndexUniforms) ]],
                                  MetalVertexIn vertexIn [[ stage_in ]])
{
    MetalVertexOut out;
    float4 position = float4(vertexIn.position, 0.0, 1.0);
    out.position = uniforms.mvpMatrix * position;
    out.color = vertexIn.color;
    
    return out;
}

fragment half4 fragment_func(MetalVertexOut input [[ stage_in ]])
{
    return half4(input.color);
}
