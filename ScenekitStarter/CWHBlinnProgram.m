//
//  CWHBlinnProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/29/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHBlinnProgram.h"

@implementation CWHBlinnProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];
    
    self = [super initWithLibrary:library vertexFunctionName:@"BlinnVertex" fragmentFunctionName:@"BlinnFragment"];
    
    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        self.ambientColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:1];
        self.lightColor = [NSColor redColor];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"BlinnVertex" fragmentFunctionName:@"BlinnFragment"];

    if (self != nil) {
        self.ambientColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"ambientColor"];
        self.lightColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"lightColor"];
        
        [self bindBuffers];

        self.delegate = self;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_ambientColor forKey:@"ambientColor"];
    [encoder encodeObject:_lightColor forKey:@"lightColor"];
}

- (void)bindBuffers {
    SCNBufferBindingBlock lightBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct LightUniforms {
            float diffuseIntensity[3];
            float ambientIntensity[3];
            float position[3];
        } lights;

        memset(&lights, 0, sizeof(lights));

        lights.position[0] = self.lightPosition.x;
        lights.position[1] = self.lightPosition.y;
        lights.position[2] = self.lightPosition.z;

        if (self.lightColor) {
            lights.diffuseIntensity[0] = [self.lightColor redComponent];
            lights.diffuseIntensity[1] = [self.lightColor greenComponent];
            lights.diffuseIntensity[2] = [self.lightColor blueComponent];
        }

        if (self.ambientColor) {
            lights.ambientIntensity[0] = [self.ambientColor redComponent];
            lights.ambientIntensity[1] = [self.ambientColor greenComponent];
            lights.ambientIntensity[2] = [self.ambientColor blueComponent];
        }

        [buffer writeBytes:&lights length:sizeof(lights)];
    };

    [self handleBindingOfBufferNamed:@"vertexLight" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"fragmentLight" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
}

#pragma  mark - SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
