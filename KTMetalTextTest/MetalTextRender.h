//
//  MetalTextRender.h
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/4.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface MetalTextRender : NSObject<MTKViewDelegate>

@property(nonatomic, strong, readonly) MDLVertexDescriptor *vertexDescriptor;

- (instancetype)initWithMTKView:(MTKView *)mtkView;

@end
