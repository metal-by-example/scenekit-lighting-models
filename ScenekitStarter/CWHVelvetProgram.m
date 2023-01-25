//
//  CWHVelvetProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/30/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHVelvetProgram.h"

@implementation CWHVelvetProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"VelvetVertex" fragmentFunctionName:@"VelvetFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        NSColor *underColor = [NSColor colorWithRed:0.7 green:0.7 blue:0 alpha:1.0];
        self.underColor = underColor;
        NSColor *fuzzColor = [NSColor colorWithRed:0.9 green:0.7 blue:0.5 alpha:1.0];
        self.fuzzColor = fuzzColor;
        self.rolloff = 0.528;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"VelvetVertex" fragmentFunctionName:@"VelvetFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        self.underColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"underColor"];
        self.fuzzColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"fuzzColor"];
        self.primaryColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"primaryColor"];
        self.rolloff = [decoder decodeDoubleForKey:@"rolloff"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_underColor forKey:@"underColor"];
    [encoder encodeObject:_fuzzColor forKey:@"fuzzColor"];
    [encoder encodeObject:_primaryColor forKey:@"primaryColor"];
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
            float primaryColor[4];
            float fuzzColor[4];
            float underColor[4];
            float rolloff;
        } material;

        if (self.primaryColor) {
            material.primaryColor[0] = self.primaryColor.redComponent;
            material.primaryColor[1] = self.primaryColor.greenComponent;
            material.primaryColor[2] = self.primaryColor.blueComponent;
            material.primaryColor[3] = self.primaryColor.alphaComponent;
        }

        if (self.fuzzColor) {
            material.fuzzColor[0] = self.fuzzColor.redComponent;
            material.fuzzColor[1] = self.fuzzColor.greenComponent;
            material.fuzzColor[2] = self.fuzzColor.blueComponent;
            material.fuzzColor[3] = self.fuzzColor.alphaComponent;
        }

        if (self.underColor) {
            material.underColor[0] = self.underColor.redComponent;
            material.underColor[1] = self.underColor.greenComponent;
            material.underColor[2] = self.underColor.blueComponent;
            material.underColor[3] = self.underColor.alphaComponent;
        }

        material.rolloff = self.rolloff;

        [buffer writeBytes:&material length:sizeof(material)];
    };

    [self handleBindingOfBufferNamed:@"light" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"material" frequency:SCNBufferFrequencyPerFrame usingBlock:materialBlock];
}

#pragma mark - SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
