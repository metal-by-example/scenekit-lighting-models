//
//  CWHEdgeFuzzProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/31/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHEdgeFuzzProgram.h"

@implementation CWHEdgeFuzzProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"EdgeFuzzVertex" fragmentFunctionName:@"EdgeFuzzFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        NSColor *surfaceColor = [NSColor colorWithRed:0.8 green:0.4 blue:0.2 alpha:1.];
        self.surfaceColor = surfaceColor;
        NSColor *edgeColor = [NSColor colorWithRed:0.4 green:0.8 blue:1. alpha:1.];
        self.edgeColor = edgeColor;
        NSColor *lightColor = [NSColor colorWithRed:1. green:1. blue:1. alpha:1.];
        self.lightColor = lightColor;
        NSColor *ambientColor = [NSColor colorWithRed:0. green:0. blue:0. alpha:1.];
        self.ambientColor = ambientColor;
        
        self.fuzziness = 0.166;
        self.edgeFade = 3.868;
        self.specularity = 0.1488;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"EdgeFuzzVertex" fragmentFunctionName:@"EdgeFuzzFragment"];

    if (self) {
        self.surfaceColor =[decoder decodeObjectOfClass:[NSColor class] forKey:@"surfaceColor"];
        self.edgeColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"edgeColor"];
        self.lightColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"lightColor"];
        self.ambientColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"ambientColor"];
        self.fuzziness  = [decoder decodeDoubleForKey:@"fuzziness"];
        self.edgeFade  = [decoder decodeDoubleForKey:@"edgeFade"];
        self.specularity  = [decoder decodeDoubleForKey:@"specularity"];

        self.delegate = self;

        [self bindBuffers];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_surfaceColor forKey:@"surfaceColor"];
    [encoder encodeObject:_edgeColor forKey:@"edgeColor"];
    [encoder encodeObject:_lightColor forKey:@"lightColor"];
    [encoder encodeObject:_ambientColor forKey:@"ambientColor"];
    [encoder encodeDouble:_fuzziness forKey:@"fuzziness"];
    [encoder encodeDouble:_edgeFade forKey:@"edgeFade"];
    [encoder encodeDouble:_specularity forKey:@"specularity"];
}

- (void)bindBuffers {
    SCNBufferBindingBlock lightBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct LightConstants {
            float position[3];
            float ambientIntensity[3];
            float diffuseIntensity[3];
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
            float edgeColor[4];
            float surfaceColor[4];
            float specularity;
            float fuzziness;
            float edgeFade;
        } material;

        if (self.edgeColor) {
            material.edgeColor[0] = [self.edgeColor redComponent];
            material.edgeColor[1] = [self.edgeColor greenComponent];
            material.edgeColor[2] = [self.edgeColor blueComponent];
            material.edgeColor[3] = [self.edgeColor alphaComponent];
        }

        if (self.surfaceColor) {
            material.surfaceColor[0] = [self.surfaceColor redComponent];
            material.surfaceColor[1] = [self.surfaceColor greenComponent];
            material.surfaceColor[2] = [self.surfaceColor blueComponent];
            material.surfaceColor[3] = [self.surfaceColor alphaComponent];
        }

        material.specularity = self.specularity;
        material.fuzziness = self.fuzziness;
        material.edgeFade = self.edgeFade;

        [buffer writeBytes:&material length:sizeof(material)];
    };

    [self handleBindingOfBufferNamed:@"vertexLights" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"fragmentLights" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"material" frequency:SCNBufferFrequencyPerShadable usingBlock:materialBlock];
}

#pragma mark - SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
