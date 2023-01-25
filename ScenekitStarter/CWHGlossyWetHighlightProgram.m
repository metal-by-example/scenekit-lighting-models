//
//  CWHGlossyWetHighlightProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/31/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHGlossyWetHighlightProgram.h"

@implementation CWHGlossyWetHighlightProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"GlossyWetHighlightVertex" fragmentFunctionName:@"GlossyWetHighlightFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        self.ambientColor = [NSColor colorWithRed:0. green:0. blue:0. alpha:1.];
        self.diffuseColor = [NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.];
        self.specularColor = [NSColor colorWithRed:1. green:0. blue:0. alpha:1.];
        self.specularity = 0.3;
        self.specularExponent = 3.0;
        self.glossMax = 1.349;
        self.glossMin = 1.199;
        self.glossDrop = 2.661;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"GlossyWetHighlightVertex" fragmentFunctionName:@"GlossyWetHighlightFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        self.ambientColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"ambientColor"];
        self.diffuseColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"diffuseColor"];
        self.specularColor = [decoder decodeObjectOfClass:[NSColor class] forKey:@"specularColor"];
        self.specularity = [decoder decodeDoubleForKey:@"specularity"];
        self.specularExponent= [decoder decodeDoubleForKey:@"specularExponent"];
        self.glossMax= [decoder decodeDoubleForKey:@"glossMax"];
        self.glossMin= [decoder decodeDoubleForKey:@"glossMin"];
        self.glossDrop = [decoder decodeDoubleForKey:@"glossDrop"];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_ambientColor forKey:@"ambientColor"];
    [encoder encodeObject:_diffuseColor forKey:@"diffuseColor"];
    [encoder encodeObject:_specularColor forKey:@"specularColor"];
    [encoder encodeDouble:_specularity forKey:@"specularity"];
    [encoder encodeDouble:_specularExponent forKey:@"specularExponent"];
    [encoder encodeDouble:_glossMax forKey:@"glossMax"];
    [encoder encodeDouble:_glossMin forKey:@"glossMin"];
    [encoder encodeDouble:_glossDrop forKey:@"glossDrop"];
}

- (void)bindBuffers {
    SCNBufferBindingBlock lightBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct LightConstants {
            float position[3];
            float ambientIntensity[3];
            float diffuseIntensity[3];
            float specularIntensity[3];
        } lights;

        lights.position[0] = self.lightPosition.x;
        lights.position[1] = self.lightPosition.y;
        lights.position[2] = self.lightPosition.z;

        if (self.ambientColor) {
            lights.ambientIntensity[0] = [self.ambientColor redComponent];
            lights.ambientIntensity[1] = [self.ambientColor greenComponent];
            lights.ambientIntensity[2] = [self.ambientColor blueComponent];
        }

        if (self.diffuseColor) {
            lights.diffuseIntensity[0] = [self.diffuseColor redComponent];
            lights.diffuseIntensity[1] = [self.diffuseColor greenComponent];
            lights.diffuseIntensity[2] = [self.diffuseColor blueComponent];
        }

        if (self.specularColor) {
            lights.specularIntensity[0] = [self.specularColor redComponent];
            lights.specularIntensity[1] = [self.specularColor greenComponent];
            lights.specularIntensity[2] = [self.specularColor blueComponent];
        }

        [buffer writeBytes:&lights length:sizeof(lights)];
    };

    SCNBufferBindingBlock materialBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct MaterialConstants {
            float specularExponent;
            float specularity;
            float glossMin;
            float glossMax;
            float glossDrop;
        } material;

        material.specularExponent = self.specularExponent;
        material.specularity = self.specularity;
        material.glossMin = self.glossMin;
        material.glossMax = self.glossMax;
        material.glossDrop = self.glossDrop;

        [buffer writeBytes:&material length:sizeof(material)];
    };

    [self handleBindingOfBufferNamed:@"vertexLights" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"fragmentLights" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"material" frequency:SCNBufferFrequencyPerFrame usingBlock:materialBlock];
}

#pragma mark - SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
