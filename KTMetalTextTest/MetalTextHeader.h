//
//  MetalTextHeader.h
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/4.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#ifndef MetalTextHeader_h
#define MetalTextHeader_h

#include <simd/simd.h>

typedef struct MetalMeshVertex {
    float x, y;
    vector_float4 color;
}MetalMeshVertex;

typedef struct {
    matrix_float4x4 mvpMatrix;
}MetalUniforms;

typedef enum {
    MetalBufferIndexVertex = 0,
    MetalBufferIndexUniforms = 1,
}MetalBufferIndex;

typedef struct {
    float x;
    float y;
}MetalPathVertex;

#endif /* MetalTextHeader_h */
