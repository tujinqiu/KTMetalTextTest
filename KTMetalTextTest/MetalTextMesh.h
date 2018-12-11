//
//  MetalTextMesh.h
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/5.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ModelIO/ModelIO.h>
#import <MetalKit/MetalKit.h>
#import <CoreText/CoreText.h>

@interface MetalTextMesh : NSObject

//+ (instancetype)meshWithText:(NSString *)text
//                        font:(UIFont *)font
//                       color:(UIColor *)color
//            vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor
//             bufferAllocator:(MTKMeshBufferAllocator *)bufferAllocator;

+ (MTKMesh *)meshWithString:(NSString *)string
                       font:(UIFont *)font
             extrusionDepth:(CGFloat)depth
           vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor
            bufferAllocator:(MTKMeshBufferAllocator *)bufferAllocator;

@end
