//
//  MetalRender.m
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/4.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#import "MetalRender.h"
#import "MetalHeader.h"
#import <GLKit/GLKit.h>

static inline matrix_float4x4 s_getMatrixFloat4x4FromGlMatrix4(GLKMatrix4 glMatrix4)
{
    matrix_float4x4 ret = (matrix_float4x4){
        simd_make_float4(glMatrix4.m00, glMatrix4.m01, glMatrix4.m02, glMatrix4.m03),
        simd_make_float4(glMatrix4.m10, glMatrix4.m11, glMatrix4.m12, glMatrix4.m13),
        simd_make_float4(glMatrix4.m20, glMatrix4.m21, glMatrix4.m22, glMatrix4.m23),
        simd_make_float4(glMatrix4.m30, glMatrix4.m31, glMatrix4.m32, glMatrix4.m33),
    };
    return ret;
}

@interface MetalRender ()

@property(nonatomic, weak) MTKView *mtkView;
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property(nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property(nonatomic, strong) id<MTLBuffer> uniformsBuffer;

@end

@implementation MetalRender

- (instancetype)initWithMTKView:(MTKView *)mtkView
{
    if (self = [super init]) {
        _mtkView = mtkView;
        mtkView.delegate = self;
        _device = mtkView.device;
        [self p_buildPipeline];
        [self p_setupBuffers];
    }
    
    return self;
}

- (void)p_buildPipeline
{
    self.commandQueue = [self.device newCommandQueue];
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_func"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_func"];
    MTLRenderPipelineDescriptor *descriptor = [MTLRenderPipelineDescriptor new];
    [descriptor setVertexFunction:vertexFunc];
    [descriptor setFragmentFunction:fragmentFunc];
    descriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;
    NSError *error = nil;
    self.renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (error) {
        NSLog(@"build pipeline error");
    }
}

- (void)p_setupBuffers
{
    static MetalVertex s_vertexData[6] = {
        {{-1.0, -1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{1.0, -1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{1.0, 1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{1.0, 1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{-1.0, 1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{-1.0, -1.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 1.0}}
    };
    self.vertexBuffer = [self.device newBufferWithBytes:s_vertexData length:sizeof(s_vertexData) options:MTLResourceStorageModeShared];
    
    GLKMatrix4 modelMatrix = GLKMatrix4MakeScale(0.5, 0.5, 1.0);
    CGFloat aspect = self.mtkView.drawableSize.width / self.mtkView.drawableSize.height;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeScale(1.0, aspect, 1.0);
    GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(projectionMatrix, modelMatrix);
    MetalUniforms uniforms;
    uniforms.mvpMatrix = s_getMatrixFloat4x4FromGlMatrix4(mvpMatrix);
    self.uniformsBuffer = [self.device newBufferWithBytes:&uniforms length:sizeof(MetalUniforms) options:MTLResourceStorageModeShared];
}

- (void)p_render
{
    id<CAMetalDrawable> drawable = self.mtkView.currentDrawable;
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    MTLRenderPassDescriptor *renderPassDescriptor = [self.mtkView currentRenderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);
    id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderCommandEncoder setRenderPipelineState:self.renderPipelineState];
    [renderCommandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderCommandEncoder setCullMode:MTLCullModeBack];
    [renderCommandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:MetalBufferIndexVertex];
    [renderCommandEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:MetalBufferIndexUniforms];
    [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderCommandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

#pragma mark - mtkview delegate

- (void)drawInMTKView:(MTKView *)view
{
    [self p_render];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    
}

@end
