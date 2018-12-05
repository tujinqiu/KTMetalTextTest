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
    float4 position [[position]];
    float4 color;
}MetalVertexOut;

vertex MetalVertexOut vertex_func(constant MetalVertex *vertexArr [[ buffer(MetalBufferIndexVertex) ]],
                                  constant MetalUniforms &uniforms [[ buffer(MetalBufferIndexUniforms) ]],
                                  uint vertexId [[ vertex_id]])
{
    MetalVertexOut out;
    MetalVertex in = vertexArr[vertexId];
    out.position = uniforms.mvpMatrix * in.position;
    out.color = in.color;
    
    return out;
}

fragment half4 fragment_func(MetalVertexOut input [[ stage_in ]])
{
    return half4(input.color);
}
