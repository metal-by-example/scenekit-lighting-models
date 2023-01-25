//
//  CWHLambSkinProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/31/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHLambSkinProgram.h"

@implementation CWHLambSkinProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"LambSkinVertex" fragmentFunctionName:@"LambSkinFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        NSColor *diffuseColor = [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
        self.diffuseColor = diffuseColor;
        NSColor *ambientColor = [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        self.ambientColor = ambientColor;
        NSColor *subColor = [NSColor colorWithRed:1. green:0.0 blue:0.0 alpha:1.0];
        self.subColor = subColor;
        self.rolloff = 0.575;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"LambSkinVertex" fragmentFunctionName:@"LambSkinFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        self.diffuseColor =[decoder decodeObjectOfClass:[NSColor class] forKey:@"diffuseColor"];
        self.ambientColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"ambientColor"];
        self.subColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"subColor"];
        self.rolloff = [decoder decodeDoubleForKey:@"rolloff"];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_diffuseColor forKey:@"diffuseColor"];
    [encoder encodeObject:_ambientColor forKey:@"ambientColor"];
    [encoder encodeObject:_subColor forKey:@"subColor"];
    [encoder encodeDouble:_rolloff forKey:@"rolloff"];
}

- (void)bindBuffers {
    SCNBufferBindingBlock lightBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct LightConstants {
            float position[3];
        } lights;

        lights.position[0] = self.lightPosition.x;
        lights.position[1] = self.lightPosition.y;
        lights.position[2] = self.lightPosition.z;

        [buffer writeBytes:&lights length:sizeof(lights)];
    };

    SCNBufferBindingBlock materialBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct MaterialConstants {
            float ambientColor[3];
            float diffuseColor[3];
            float subColor[3];
            float rolloff;
        } material;

        if (self.ambientColor) {
            material.ambientColor[0] = self.ambientColor.redComponent;
            material.ambientColor[1] = self.ambientColor.greenComponent;
            material.ambientColor[2] = self.ambientColor.blueComponent;
        }

        if (self.diffuseColor) {
            material.diffuseColor[0] = self.diffuseColor.redComponent;
            material.diffuseColor[1] = self.diffuseColor.greenComponent;
            material.diffuseColor[2] = self.diffuseColor.blueComponent;
        }

        if (self.subColor) {
            material.subColor[0] = self.subColor.redComponent;
            material.subColor[1] = self.subColor.greenComponent;
            material.subColor[2] = self.subColor.blueComponent;
        }

        material.rolloff = self.rolloff;

        [buffer writeBytes:&material length:sizeof(material)];
    };

    [self handleBindingOfBufferNamed:@"light" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"material" frequency:SCNBufferFrequencyPerFrame usingBlock:materialBlock];
}

#pragma mark -  SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
