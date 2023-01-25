//
//  CWHBlinnProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/29/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHPhongPointLightProgram.h"

@implementation CWHPhongPointLightProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"PhongVertex" fragmentFunctionName:@"PhongFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        self.ambientColor = [NSColor colorWithRed:0. green:0. blue:0. alpha:1.];
        self.lightColor = [NSColor redColor];
        self.materialSpecularity = 1;
        self.shininess = 10.8;

    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"PhongVertex" fragmentFunctionName:@"PhongFragment"];

    if (self != nil) {
        self.ambientColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"ambientColor"];
        self.lightColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"lightColor"];
        self.materialSpecularity = [decoder decodeDoubleForKey:@"materialSpecularity"];
        self.shininess = [decoder decodeDoubleForKey:@"shininess"];

        [self bindBuffers];

        self.delegate = self;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_ambientColor forKey:@"ambientColor"];
    [encoder encodeObject:_lightColor forKey:@"lightColor"];
    [encoder encodeDouble:_materialSpecularity forKey:@"materialSpecularity"];
    [encoder encodeDouble:_shininess forKey:@"shininess"];
}

- (void)bindBuffers {
    SCNBufferBindingBlock lightBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct LightConstants {
            float position[3];
            float diffuseIntensity[3];
            float ambientIntensity[3];
        } lights;

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

    SCNBufferBindingBlock materialBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct MaterialConstants {
            float specularColor[3];
            float shininess;
        } material;

        material.specularColor[0] = self.materialSpecularity;
        material.specularColor[1] = self.materialSpecularity;
        material.specularColor[2] = self.materialSpecularity;
        material.shininess = self.shininess;

        [buffer writeBytes:&material length:sizeof(material)];
    };

    [self handleBindingOfBufferNamed:@"vertexLight" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"fragmentLight" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"material" frequency:SCNBufferFrequencyPerShadable usingBlock:materialBlock];
}

#pragma mark -  SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}



@end
