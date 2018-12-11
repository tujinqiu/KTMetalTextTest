//
//  MetalTextMesh.m
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/5.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#import "MetalTextMesh.h"
#import "tesselator.h"
#import "MetalTextMeshHeader.h"

#define USE_ADAPTIVE_SUBDIVISION 0
#define DEFAULT_QUAD_CURVE_SUBDIVISIONS 5

typedef UInt32 MetalIndexType;

static inline float s_lerp(float a, float b, float t)
{
    return a + t * (b - a);
}

static inline CGPoint s_lerpPoints(CGPoint a, CGPoint b, float t)
{
    return CGPointMake(s_lerp(a.x, b.x, t), s_lerp(a.y, b.y, t));
}

// Maps a value t in a range [a, b] to the range [c, d]
static inline float s_remap(float a, float b, float c, float d, float t)
{
    float p = (t - a) / (b - a);
    return c + p * (d - c);
}

static inline CGPoint s_evalQuadCurve(CGPoint a, CGPoint b, CGPoint c, CGFloat t)
{
    CGPoint q0 = s_lerpPoints(a, c, t);
    CGPoint q1 = s_lerpPoints(c, b, t);
    return s_lerpPoints(q0, q1, t);
}

static void s_flattenQuadCurvePath(CGMutablePathRef flattenedPath,
                                   const CGPathElement *element,
                                   CGFloat flatness)
{
#if USE_ADAPTIVE_SUBDIVISION
    const int MAX_SUBDIVS = 20;
    const CGPoint a = CGPathGetCurrentPoint(flattenedPath); // "from" point
    const CGPoint b = element->points[1]; // "to" point
    const CGPoint c = element->points[0]; // control point
    const CGFloat tolSq = flatness * flatness; // maximum tolerable squared error
    CGFloat t = 0; // Parameter of the curve up to which we've subdivided
    CGFloat candT = 0.5; // "Candidate" parameter of the curve we're currently evaluating
    CGPoint p = a; // Point along curve at parameter t
    while (t < 1.0) {
        int subdivs = 1;
        CGFloat err = FLT_MAX; // Squared distance from midpoint of candidate segment to midpoint of true curve segment
        CGPoint candP = p;
        candT = fmin(1.0, t + 0.5);
        while (err > tolSq) {
            candP = s_evalQuadCurve(a, b, c, candT);
            CGFloat midT = (t + candT) / 2;
            CGPoint midCurve = s_evalQuadCurve(a, b, c, midT);
            CGPoint midSeg = s_lerpPoints(p, candP, 0.5);
            err = pow(midSeg.x - midCurve.x, 2) + pow(midSeg.y - midCurve.y, 2);
            if (err > tolSq) {
                candT = t + 0.5 * (candT - t);
                if (++subdivs > MAX_SUBDIVS) {
                    break;
                }
            }
        }
        t = candT;
        p = candP;
        CGPathAddLineToPoint(flattenedPath, NULL, p.x, p.y);
    }
#else
    CGPoint a = CGPathGetCurrentPoint(flattenedPath);
    CGPoint b = element->points[1];
    CGPoint c = element->points[0];
    for (int i = 0; i < DEFAULT_QUAD_CURVE_SUBDIVISIONS; ++i) {
        float t = (float)i / (DEFAULT_QUAD_CURVE_SUBDIVISIONS - 1);
        CGPoint r = s_evalQuadCurve(a, b, c, t);
        CGPathAddLineToPoint(flattenedPath, NULL, r.x, r.y);
    }
#endif
}

static inline CGPoint s_evalCurve(CGPoint a, CGPoint b, CGPoint c1, CGPoint c2, CGFloat t)
{
    CGPoint q0 = s_lerpPoints(a, c1, t);
    CGPoint q1 = s_lerpPoints(c1, c2, t);
    CGPoint q2 = s_lerpPoints(c2, b, t);
    return s_evalQuadCurve(q0, q2, q1, t);
}

static void s_flattenCurvePath(CGMutablePathRef flattenedPath,
                               const CGPathElement *element,
                               CGFloat flatness)
{
#if USE_ADAPTIVE_SUBDIVISION
    const int MAX_SUBDIVS = 20;
    const CGPoint a = CGPathGetCurrentPoint(flattenedPath); // "from" point
    const CGPoint b = element->points[2]; // "to" point
    const CGPoint c1 = element->points[0]; // control point1
    const CGPoint c2 = element->points[1]; // control point2
    const CGFloat tolSq = flatness * flatness; // maximum tolerable squared error
    CGFloat t = 0; // Parameter of the curve up to which we've subdivided
    CGFloat candT = 0.5; // "Candidate" parameter of the curve we're currently evaluating
    CGPoint p = a; // Point along curve at parameter t
    while (t < 1.0) {
        int subdivs = 1;
        CGFloat err = FLT_MAX; // Squared distance from midpoint of candidate segment to midpoint of true curve segment
        CGPoint candP = p;
        candT = fmin(1.0, t + 0.5);
        while (err > tolSq) {
            candP = s_evalCurve(a, b, c1, c2, candT);
            CGFloat midT = (t + candT) / 2;
            CGPoint midCurve = s_evalCurve(a, b, c1, c2, midT);
            CGPoint midSeg = s_lerpPoints(p, candP, 0.5);
            err = pow(midSeg.x - midCurve.x, 2) + pow(midSeg.y - midCurve.y, 2);
            if (err > tolSq) {
                candT = t + 0.5 * (candT - t);
                if (++subdivs > MAX_SUBDIVS) {
                    break;
                }
            }
        }
        t = candT;
        p = candP;
        CGPathAddLineToPoint(flattenedPath, NULL, p.x, p.y);
    }
#else
    CGPoint a = CGPathGetCurrentPoint(flattenedPath);
    CGPoint b = element->points[2];
    CGPoint c1 = element->points[0];
    CGPoint c2 = element->points[1];
    for (int i = 0; i < DEFAULT_QUAD_CURVE_SUBDIVISIONS; ++i) {
        float t = (float)i / (DEFAULT_QUAD_CURVE_SUBDIVISIONS - 1);
        CGPoint r = s_evalCurve(a, b, c1, c2, t);
        CGPathAddLineToPoint(flattenedPath, NULL, r.x, r.y);
    }
#endif
}

@implementation MetalTextMesh

+ (MTKMesh *)meshWithString:(NSString *)string
                       font:(UIFont *)font
                      color:(UIColor *)color
           vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor
            bufferAllocator:(MTKMeshBufferAllocator *)bufferAllocator
{
    // Create an attributed string from the provided text; we make our own attributed string
    // to ensure that the entire mesh has a single style, which simplifies things greatly.
    NSDictionary *attributes = @{ NSFontAttributeName : font };
    CFAttributedStringRef attributedString = CFAttributedStringCreate(NULL,
                                                                      (__bridge CFStringRef)string,
                                                                      (__bridge CFDictionaryRef)attributes);
    CGFloat r, g, b, a = 0;
    [color getRed:&r green:&g blue:&b alpha:&a];
    vector_float4 colorVec = simd_make_float4(r, g, b, a);
    
    // Transform the attributed string to a linked list of glyphs, each with an associated path from the specified font
    MetalGlyph *glyphs = [self p_glyphsForAttributedString:attributedString];
    
    CFRelease(attributedString);
    
    // Flatten the paths associated with the glyphs so we can more easily tessellate them in the next step
    [self p_flattenPathsForGlyphs:glyphs];
    
    // Tessellate the glyphs into contours and actual mesh geometry
    [self p_tessellatePathsForGlyphs:glyphs];
    
    // Figure out how much space we need in our vertex and index buffers to accommodate the mesh
    NSUInteger vertexCount = 0, indexCount = 0;
    [self calculateVertexCount:&vertexCount indexCount:&indexCount forGlyphs:glyphs];
    
    // Allocate the vertex and index buffers
    id<MDLMeshBuffer> vertexBuffer = [bufferAllocator newBuffer:vertexCount * sizeof(MetalMeshVertex)
                                                           type:MDLMeshBufferTypeVertex];
    id<MDLMeshBuffer> indexBuffer = [bufferAllocator newBuffer:indexCount * sizeof(MetalIndexType)
                                                          type:MDLMeshBufferTypeIndex];
    
    // Write text mesh geometry into the vertex and index buffers
    NSUInteger vertexBufferOffset = 0, indexBufferOffset = 0;
    [self p_writeVerticesForGlyphs:glyphs
                            buffer:vertexBuffer
                            offset:&vertexBufferOffset
                             color:colorVec];
    
    [self p_writeIndicesForGlyphs:glyphs
                           buffer:indexBuffer
                           offset:&indexBufferOffset];
    
    MetalGlyphListFree(glyphs);
    
    // Use ModelIO to create a mesh object, then return a MetalKit mesh we can render later
    MDLSubmesh *submesh = [[MDLSubmesh alloc] initWithIndexBuffer:indexBuffer
                                                       indexCount:indexCount
                                                        indexType:MDLIndexBitDepthUInt32
                                                     geometryType:MDLGeometryTypeTriangles
                                                         material:nil];
    NSArray *submeshes = @[submesh];
    MDLMesh *mdlMesh = [self p_meshForVertexBuffer:vertexBuffer
                                       vertexCount:vertexCount
                                         submeshes:submeshes
                                  vertexDescriptor:vertexDescriptor];
    
    NSError *error = nil;
    MTKMesh *mesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:bufferAllocator.device error:&error];
    if (error) {
        NSLog(@"Unable to create MTK mesh from MDL mesh");
    }
    return mesh;
}

+ (MetalGlyph *)p_glyphsForAttributedString:(CFAttributedStringRef)attributedString
{
    MetalGlyph *head = NULL, *tail = NULL;
    
    // Create a typesetter and use it to lay out a single line of text
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString(attributedString);
    CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(0, 0));
    NSArray *runs = (__bridge NSArray *)CTLineGetGlyphRuns(line);
    
    // For each of the runs, of which there should only be one...
    for (int runIdx = 0; runIdx < runs.count; ++runIdx) {
        CTRunRef run = (__bridge CTRunRef)runs[runIdx];
        const CFIndex glyphCount = CTRunGetGlyphCount(run);
        
        // Retrieve the list of glyph positions so we know how to transform the paths we get from the font
        CGPoint *glyphPositions = malloc(sizeof(CGPoint) * glyphCount);
        CTRunGetPositions(run, CFRangeMake(0, 0), glyphPositions);
        
        // Retrieve the bounds of the text, so we can crudely center it
        CGRect bounds = CTRunGetImageBounds(run, NULL, CFRangeMake(0, 0));
        bounds.origin.x -= bounds.size.width / 2;
        
        CGGlyph *glyphs = malloc(sizeof(CGGlyph) * glyphCount);
        CTRunGetGlyphs(run, CFRangeMake(0, 0), glyphs);
        
        // Fetch the font from the current run. We could have taken this as a parameter, but this is more future-proof.
        NSDictionary *runAttributes = (__bridge NSDictionary *)CTRunGetAttributes(run);
        CTFontRef font = (__bridge CTFontRef)runAttributes[NSFontAttributeName];
        
        // For each glyph in the run...
        for (int glyphIdx = 0; glyphIdx < glyphCount; ++glyphIdx) {
            // Compute a transform that will position the glyph correctly relative to the others, accounting for centering
            CGPoint glyphPosition = glyphPositions[glyphIdx];
            CGAffineTransform glyphTransform = CGAffineTransformMakeTranslation(glyphPosition.x - bounds.size.width / 2,
                                                                                glyphPosition.y);
            
            // Retrieve the actual path for this glyph from the font
            CGPathRef path = CTFontCreatePathForGlyph(font, glyphs[glyphIdx], &glyphTransform);
            
            if (path == NULL) {
                continue; // non-printing and whitespace characters have no associated path
            }
            
            // Add the glyph to the list of glyphs, creating the list if this is the first glyph
            if (head == NULL) {
                head = MetalGlyphCreate();
                tail = head;
            } else {
                tail->next = MetalGlyphCreate();
                tail = tail->next;
            }
            
            tail->path = path;
        }
        
        free(glyphPositions);
        free(glyphs);
    }
    
    CFRelease(typesetter);
    CFRelease(line);
    
    return head;
}

+ (void)p_flattenPathsForGlyphs:(MetalGlyph *)glyphs
{
    MetalGlyph *glyph = glyphs;
    // For each glyph, replace its non-flattened path with a flattened path
    while (glyph) {
        CGPathRef flattenedPath = [self p_newFlattenedPathForPath:glyph->path flatness:0.1];
        CFRelease(glyph->path);
        glyph->path = flattenedPath;
        
        glyph = glyph->next;
    }
}

+ (CGPathRef)p_newFlattenedPathForPath:(CGPathRef)path
                              flatness:(CGFloat)flatness
{
    CGMutablePathRef flattenedPath = CGPathCreateMutable();
    // Iterate the elements in the path, converting curve segments into sequences of small line segments
    CGPathApplyWithBlock(path, ^(const CGPathElement *element) {
        switch (element->type) {
            case kCGPathElementMoveToPoint: {
                CGPoint point = element->points[0];
                CGPathMoveToPoint(flattenedPath, NULL, point.x, point.y);
                break;
            }
                
            case kCGPathElementAddLineToPoint: {
                CGPoint point = element->points[0];
                CGPathAddLineToPoint(flattenedPath, NULL, point.x, point.y);
                break;
            }
                
            case kCGPathElementAddCurveToPoint:
                s_flattenCurvePath(flattenedPath, element, flatness);
                break;
                
            case kCGPathElementAddQuadCurveToPoint:
                s_flattenQuadCurvePath(flattenedPath, element, flatness);
                break;
                
            case kCGPathElementCloseSubpath:
                CGPathCloseSubpath(flattenedPath);
                break;
        }
    });
    
    return flattenedPath;
}

+ (void)p_tessellatePathsForGlyphs:(MetalGlyph *)glyphs
{
    // Create a new libtess tessellator, requesting constrained Delaunay triangulation
    TESStesselator *tess = tessNewTess(NULL);
    tessSetOption(tess, TESS_CONSTRAINED_DELAUNAY_TRIANGULATION, 1);
    
    const int polygonIndexCount = 3; // triangles only
    
    MetalGlyph *glyph = glyphs;
    while (glyph) {
        // Accumulate the contours of the flattened path into the tessellator so it can compute the CDT
        MetalPathContour *contours = [self p_tessellatePath:glyph->path usingTessellator:tess];
        
        // Do the actual tessellation work
        int result = tessTesselate(tess, TESS_WINDING_ODD, TESS_POLYGONS, polygonIndexCount, VERT_COMPONENT_COUNT, NULL);
        if (!result) {
            NSLog(@"Unable to tessellate path");
        }
        
        // Retrieve the tessellated mesh from the tessellator and copy the contour list and geometry to the current glyph
        int vertexCount = tessGetVertexCount(tess);
        const TESSreal *vertices = tessGetVertices(tess);
        int indexCount = tessGetElementCount(tess) * polygonIndexCount;
        const TESSindex *indices = tessGetElements(tess);
        
        glyph->contours = contours;
        
        MetalGlyphSetGeometry(glyph, vertexCount, vertices, indexCount, indices);
        
        glyph = glyph->next;
    }
    
    tessDeleteTess(tess);
}

+ (MetalPathContour *)p_tessellatePath:(CGPathRef)path
                      usingTessellator:(TESStesselator *)tessellator
{
    __block MetalPathContour *contour = MetalPathContourCreate();
    MetalPathContour *contours = contour;
    // Iterate the line segments in the flattened path, accumulating each subpath as a contour,
    // then pass closed contours to the tessellator
    CGPathApplyWithBlock(path, ^(const CGPathElement *element){
        switch (element->type) {
            case kCGPathElementMoveToPoint: {
                CGPoint point = element->points[0];
                if (MetalPathContourGetVertexCount(contour) != 0) {
                    NSLog(@"Open subpaths are not supported; all contours must be closed");
                }
                MetalPathContourAddVertex(contour, MetalPathVertexMake(point.x, point.y));
                break;
            }
            case kCGPathElementAddLineToPoint: {
                CGPoint point = element->points[0];
                MetalPathContourAddVertex(contour, MetalPathVertexMake(point.x, point.y));
                break;
            }
            case kCGPathElementAddCurveToPoint:
            case kCGPathElementAddQuadCurveToPoint:
                assert(!"Tessellator does not expect curve segments; flatten path first");
                break;
            case kCGPathElementCloseSubpath: {
                MetalPathVertex *vertices = MetalPathContourGetVertices(contour);
                int vertexCount = MetalPathContourGetVertexCount(contour);
                tessAddContour(tessellator, 2, vertices, sizeof(MetalPathVertex), vertexCount);
                contour->next = MetalPathContourCreate();
                contour = contour->next;
                break;
            }
        }
    });
    return contours;
}

+ (void)calculateVertexCount:(NSUInteger *)vertexBufferCount
                  indexCount:(NSUInteger *)indexBufferCount
                   forGlyphs:(MetalGlyph *)glyphs
{
    *vertexBufferCount = 0;
    *indexBufferCount = 0;
    
    MetalGlyph *glyph = glyphs;
    while (glyph) {
        *vertexBufferCount += glyph->vertexCount;
        *indexBufferCount += glyph->indexCount;
        
        glyph = glyph->next;
    }
}

+ (void)p_writeVerticesForGlyphs:(MetalGlyph *)glyphs
                          buffer:(id<MDLMeshBuffer>)vertexBuffer
                          offset:(NSUInteger *)offset
                           color:(vector_float4)color
{
    MDLMeshBufferMap *map = [vertexBuffer map];
    
    MetalGlyph *glyph = glyphs;
    while (glyph) {
        MetalMeshVertex *vertices = (MetalMeshVertex *)(map.bytes + *offset);
        for (size_t i = 0; i < glyph->vertexCount; ++i) {
            float x = glyph->vertices[i * VERT_COMPONENT_COUNT + 0];
            float y = glyph->vertices[i * VERT_COMPONENT_COUNT + 1];
            
            vertices[i].x = x;
            vertices[i].y = y;
            vertices[i].color = color;
        }
        *offset += glyph->vertexCount * sizeof(MetalMeshVertex);
        glyph = glyph->next;
    }
}

+ (void)p_writeIndicesForGlyphs:(MetalGlyph *)glyphs
                         buffer:(id<MDLMeshBuffer>)indexBuffer
                         offset:(NSUInteger *)offset
{
    MDLMeshBufferMap *indexMap = [indexBuffer map];
    
    MetalGlyph *glyph = glyphs;
    UInt32 baseVertex = 0;
    while (glyph) {
        MetalIndexType *indices = (MetalIndexType *)(indexMap.bytes + *offset);
        for (size_t i = 0; i < glyph->indexCount; i += 3) {
            indices[i + 2] = glyph->indices[i + 0] + baseVertex;
            indices[i + 1] = glyph->indices[i + 1] + baseVertex;
            indices[i + 0] = glyph->indices[i + 2] + baseVertex;
        }
        *offset += glyph->indexCount * sizeof(MetalIndexType);
        baseVertex += glyph->vertexCount;
        
        glyph = glyph->next;
    }
}

+ (MDLMesh *)p_meshForVertexBuffer:(id<MDLMeshBuffer>)vertexBuffer
                       vertexCount:(NSUInteger)vertexCount
                         submeshes:(NSArray<MDLSubmesh *> *)submeshes
                  vertexDescriptor:(MDLVertexDescriptor *)vertexDescriptor
{
    MDLMesh *mdlMesh = [[MDLMesh alloc] initWithVertexBuffer:vertexBuffer
                                                 vertexCount:vertexCount
                                                  descriptor:vertexDescriptor
                                                   submeshes:submeshes];
    
    [mdlMesh addNormalsWithAttributeNamed:MDLVertexAttributeNormal creaseThreshold:sqrt(2)/2];
    
    return mdlMesh;
}

@end
