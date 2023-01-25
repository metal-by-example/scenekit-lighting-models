//
//  CWHThinFilmProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 8/28/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHThinFilmProgram.h"

@implementation CWHThinFilmProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"ThinFilmVertex" fragmentFunctionName:@"ThinFilmFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        self.imagePath = [[NSBundle mainBundle] pathForResource:@"FringeMap" ofType:@"png"];
        
        [self bindBuffers];

        self.filmDepth = 0.75;
        self.diffuseColor = [NSColor grayColor];
        
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"ThinFilmVertex" fragmentFunctionName:@"ThinFilmFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        NSString *imagePath =[decoder decodeObjectOfClass:[NSString class] forKey:@"imagePath"];
        if (imagePath) {
           self.imagePath  = imagePath;
        } else {
            self.imagePath = [[NSBundle mainBundle] pathForResource:@"FringeMap" ofType:@"png"];
        }

        [self bindBuffers];

        self.diffuseColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"diffuseColor"];
        self.filmDepth = [decoder decodeDoubleForKey:@"filmDepth"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_imagePath forKey:@"imagePath"];
    [encoder encodeObject:_diffuseColor forKey:@"diffuseColor"];
    [encoder encodeDouble:_filmDepth  forKey:@"filmDepth"];
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
            float filmDepth;
        } material;

        if (self.diffuseColor) {
            material.diffuseColor[0] = self.diffuseColor.redComponent;
            material.diffuseColor[1] = self.diffuseColor.greenComponent;
            material.diffuseColor[2] = self.diffuseColor.blueComponent;
            material.diffuseColor[3] = self.diffuseColor.alphaComponent;
        }
        
        material.filmDepth = self.filmDepth;
        
        [buffer writeBytes:&material length:sizeof(material)];
    };
    
    [self handleBindingOfBufferNamed:@"light" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"vertexMaterial" frequency:SCNBufferFrequencyPerFrame usingBlock:materialBlock];
    [self handleBindingOfBufferNamed:@"fragmentMaterial" frequency:SCNBufferFrequencyPerFrame usingBlock:materialBlock];
}

- (NSDictionary *)shadableProperties {
    NSDictionary *properties = @{
        @"fringeMap" : [SCNMaterialProperty materialPropertyWithContents:self.imagePath]
    };
    return properties;
}

#pragma mark - SCNProgramDelegate Protocol Methods
- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
