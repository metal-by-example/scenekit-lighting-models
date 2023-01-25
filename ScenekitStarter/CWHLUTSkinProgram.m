//
//  CWHLUTSkinProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/31/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHLUTSkinProgram.h"

@implementation CWHLUTSkinProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"LUTSkinVertex" fragmentFunctionName:@"LUTSkinFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        self.diffuseColor = [NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];;
        self.specularColor = [NSColor whiteColor];
        self.scatterColor = [NSColor redColor];
        self.wrap = 0.58;
        self.scatterWidth = 0.10;
        self.shininess = 0.35;        
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"LUTSkinVertex" fragmentFunctionName:@"LUTSkinFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        self.diffuseColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"diffuseColor"];
        self.specularColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"specularColor"];
        self.scatterColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"scatterColor"];
        self.wrap = [decoder decodeDoubleForKey:@"wrap"];
        self.scatterWidth = [decoder decodeDoubleForKey:@"scatterWidth"];
        self.shininess = [decoder decodeDoubleForKey:@"shininess"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_diffuseColor forKey:@"diffuseColor"];
    [encoder encodeObject:_specularColor forKey:@"specularColor"];
    [encoder encodeObject:_scatterColor forKey:@"scatterColor"];
    [encoder encodeDouble:_wrap forKey:@"wrap"];
    [encoder encodeDouble:_scatterWidth forKey:@"scatterWidth"];
    [encoder encodeDouble:_shininess forKey:@"shininess"];
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
            float diffuseColor[4];
            float specularColor[4];
        } material;

        if (self.diffuseColor) {
            material.diffuseColor[0] = self.diffuseColor.redComponent;
            material.diffuseColor[1] = self.diffuseColor.greenComponent;
            material.diffuseColor[2] = self.diffuseColor.blueComponent;
            material.diffuseColor[3] = self.diffuseColor.alphaComponent;
        }

        if (self.specularColor) {
            material.specularColor[0] = self.specularColor.redComponent;
            material.specularColor[1] = self.specularColor.greenComponent;
            material.specularColor[2] = self.specularColor.blueComponent;
            material.specularColor[3] = self.specularColor.alphaComponent;
        }

        [buffer writeBytes:&material length:sizeof(material)];
    };

    [self handleBindingOfBufferNamed:@"light" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"material" frequency:SCNBufferFrequencyPerShadable usingBlock:materialBlock];
}

- (NSDictionary *)shadableProperties {
    NSDictionary *properties = @{
        @"skinLUT" : [SCNMaterialProperty materialPropertyWithContents:@""]
    };
    return properties;
}

#pragma mark -  SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
