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
    float x, y, z;
    float nx, ny, nz;
    float s, t;
}MetalMeshVertex;

typedef struct {
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 projectionMatrix;
}MetalUniforms;

typedef enum {
    MetalBufferIndexUniforms = 0,
    MetalBufferIndexVertex = 1,
}MetalBufferIndex;

typedef enum {
    MetalFragmentTextureIndex = 0,
}MetalFragmentIndex;

typedef struct {
    float x;
    float y;
}MetalPathVertex;

#endif /* MetalTextHeader_h */
