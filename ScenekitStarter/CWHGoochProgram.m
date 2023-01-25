//
//  CWHBlinnProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/29/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHGoochProgram.h"

@implementation CWHGoochProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"GoochVertex" fragmentFunctionName:@"GoochFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        NSColor *surfaceColor = [NSColor redColor];
        self.surfaceColor = surfaceColor;
        
        NSColor *coolColor = [NSColor colorWithRed:0.2 green:1.0 blue:0.2 alpha:1.0];
        self.coolColor = coolColor;

        NSColor *warmColor = [NSColor purpleColor];
        self.warmColor = warmColor;

        self.diffuseCool = 0.0;
        self.diffuseWarm = 1.0;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"GoochVertex" fragmentFunctionName:@"GoochFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        self.coolColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"coolColor"];
        self.warmColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"warmColor"];
        self.surfaceColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"surfaceColor"];
        self.diffuseCool = [decoder decodeDoubleForKey:@"diffuseCool"];
        self.diffuseWarm = [decoder decodeDoubleForKey:@"diffuseWarm"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_coolColor forKey:@"coolColor"];
    [encoder encodeObject:_warmColor forKey:@"warmColor"];
    [encoder encodeObject:_surfaceColor forKey:@"surfaceColor"];
    [encoder encodeDouble:_diffuseCool forKey:@"diffuseCool"];
    [encoder encodeDouble:_diffuseWarm forKey:@"diffuseWarm"];
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
            float surfaceColor[4];
            float warmColor[4];
            float coolColor[4];
            float diffuseWarm;
            float diffuseCool;
        } material;

        if (self.surfaceColor) {
            material.surfaceColor[0] = self.surfaceColor.redComponent;
            material.surfaceColor[1] = self.surfaceColor.greenComponent;
            material.surfaceColor[2] = self.surfaceColor.blueComponent;
            material.surfaceColor[3] = self.surfaceColor.alphaComponent;
        }

        if (self.warmColor) {
            material.warmColor[0] = self.warmColor.redComponent;
            material.warmColor[1] = self.warmColor.greenComponent;
            material.warmColor[2] = self.warmColor.blueComponent;
            material.warmColor[3] = self.warmColor.alphaComponent;
        }

        if (self.coolColor) {
            material.coolColor[0] = self.coolColor.redComponent;
            material.coolColor[1] = self.coolColor.greenComponent;
            material.coolColor[2] = self.coolColor.blueComponent;
            material.coolColor[3] = self.coolColor.alphaComponent;
        }

        material.diffuseWarm = self.diffuseWarm;
        material.diffuseCool = self.diffuseCool;

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
