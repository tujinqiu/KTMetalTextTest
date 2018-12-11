//
//  MetalTextMeshHeader.h
//  KTMetalTextTest
//
//  Created by tu jinqiu on 2018/12/7.
//  Copyright © 2018年 tu jinqiu. All rights reserved.
//

#ifndef MetalTextMeshHeader_h
#define MetalTextMeshHeader_h

#import "MetalTextHeader.h"

static inline MetalPathVertex s_MetalPathVertexMake(float x, float y)
{
    MetalPathVertex v = {x, y};
    return v;
}

typedef struct MetalPathContour {
    MetalPathVertex *vertices;
    int vertexCount;
    int capacity;
    struct MetalPathContour *next;
}MetalPathContour;

static inline MetalPathContour * MetalPathContourCreate()
{
    MetalPathContour *contour = (MetalPathContour *)malloc(sizeof(MetalPathContour));
    contour->capacity = 32;
    contour->vertexCount = 0;
    contour->vertices = (MetalPathVertex *)malloc(contour->capacity * sizeof(MetalPathVertex));
    contour->next = NULL;
    return contour;
}

static inline void MetalPathContourAddVertex(MetalPathContour *contour, MetalPathVertex v)
{
    int i = contour->vertexCount;
    if (i >= contour->capacity - 1) {
        MetalPathVertex *old = contour->vertices;
        contour->capacity *= 1.61; // Engineering approximation to the golden ratio
        contour->vertices = (MetalPathVertex *)malloc(contour->capacity * sizeof(MetalPathVertex));
        memcpy(contour->vertices, old, contour->vertexCount * sizeof(MetalPathVertex));
        free(old);
    }
    contour->vertices[i] = v;
    contour->vertexCount++;
}

static inline int MetalPathContourGetVertexCount(MetalPathContour *contour)
{
    return contour->vertexCount;
}

static inline MetalPathVertex *MetalPathContourGetVertices(MetalPathContour *contour)
{
    return contour->vertices;
}

static inline void MetalPathContourListFree(MetalPathContour *contour) {
    if (contour) {
        if (contour->next) {
            MetalPathContourListFree(contour->next);
        }
        free(contour->vertices);
        free(contour);
    }
}

typedef struct MetalGlyph {
    CGPathRef path;
    MetalPathContour *contours;
    UInt32 vertexCount;
    TESSreal *vertices;
    UInt32 indexCount;
    TESSindex *indices;
    struct MetalGlyph *next;
}MetalGlyph;

static inline MetalGlyph *GlyphCreate()
{
    MetalGlyph *glyph = (MetalGlyph *)malloc(sizeof(MetalGlyph));
    bzero(glyph, sizeof(MetalGlyph));
    return glyph;
}

static inline void MetalGlyphListFree(MetalGlyph *glyph)
{
    if (glyph) {
        if (glyph->next) {
            MetalGlyphListFree(glyph->next);
        }
        MetalPathContourListFree(glyph->contours);
        CFRelease(glyph->path);
        free(glyph->vertices);
        free(glyph->indices);
        free(glyph);
    }
}

static inline void MetalGlyphSetGeometry(MetalGlyph *glyph,
                                         size_t vertexCount,
                                         const TESSreal *vertices,
                                         size_t indexCount,
                                         const TESSindex *indices)
{
    free(glyph->vertices);
    free(glyph->indices);
    
    glyph->vertexCount = (UInt32)vertexCount;
    size_t vertexByteCount = vertexCount * 2 * sizeof(TESSreal);
    glyph->vertices = malloc(vertexByteCount);
    memcpy(glyph->vertices, vertices, vertexByteCount);
    
    glyph->indexCount = (UInt32)indexCount;
    size_t indexByteCount = indexCount * sizeof(TESSindex);
    glyph->indices = malloc(indexByteCount);
    memcpy(glyph->indices, indices, indexByteCount);
}

#endif /* MetalTextMeshHeader_h */
