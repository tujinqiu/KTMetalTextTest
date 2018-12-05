//
//  MetalHeader.h
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/4.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#ifndef MetalHeader_h
#define MetalHeader_h

#include <simd/simd.h>

typedef struct {
    vector_float4 position;
    vector_float4 color;
}MetalVertex;

typedef struct {
    matrix_float4x4 mvpMatrix;
}MetalUniforms;

typedef enum {
    MetalBufferIndexVertex = 0,
    MetalBufferIndexUniforms = 1
}MetalBufferIndex;

#endif /* MetalHeader_h */
