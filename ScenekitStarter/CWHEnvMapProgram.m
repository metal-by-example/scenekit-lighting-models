//
//  CWHEnvMapProgram.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 8/25/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHEnvMapProgram.h"

@interface CWHEnvMapProgram ()
@property (nonatomic, readonly) NSDictionary<NSString *, id> *shadableProperties;
@end

@implementation CWHEnvMapProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

- (instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"EnvMapVertex" fragmentFunctionName:@"EnvMapFragment"];

    if (self != nil)
    {
        self.delegate = self;

        [self bindBuffers];

        NSColor *diffuseColor = [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.];
        self.diffuseColor = diffuseColor;
        NSColor *ambientColor = [NSColor colorWithRed:0. green:0. blue:0. alpha:1.];
        self.ambientColor = ambientColor;
        self.ratio = 0.875;
        self.imagePath = [[NSBundle mainBundle] pathForResource:@"EnvMapInterior" ofType:@"png"];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"EnvMapVertex" fragmentFunctionName:@"EnvMapFragment"];

    if (self != nil) {
        self.delegate = self;

        [self bindBuffers];

        self.diffuseColor =[decoder decodeObjectOfClass:[NSColor class] forKey:@"diffuseColor"];
        self.ambientColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"ambientColor"];
        self.ratio  = [decoder decodeDoubleForKey:@"ratio"];
        self.imagePath = [decoder decodeObjectOfClass:[NSString class] forKey:@"imagePath"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_diffuseColor forKey:@"diffuseColor"];
    [encoder encodeObject:_ambientColor forKey:@"ambientColor"];
    [encoder encodeDouble:_ratio forKey:@"ratio"];
    [encoder encodeObject:_imagePath forKey:@"imagePath"];
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

        if (self.diffuseColor) {
            lights.diffuseIntensity[0] = [self.diffuseColor redComponent];
            lights.diffuseIntensity[1] = [self.diffuseColor greenComponent];
            lights.diffuseIntensity[2] = [self.diffuseColor blueComponent];
        }

        if (self.ambientColor) {
            lights.ambientIntensity[0] = [self.ambientColor redComponent];
            lights.ambientIntensity[1] = [self.ambientColor greenComponent];
            lights.ambientIntensity[2] = [self.ambientColor blueComponent];
        }

        [buffer writeBytes:&lights length:sizeof(lights)];
    };

    [self handleBindingOfBufferNamed:@"vertexLights" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"fragmentLights" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
    [self handleBindingOfBufferNamed:@"ratio" frequency:SCNBufferFrequencyPerFrame usingBlock:
     ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        float ratio = self.ratio;
        [buffer writeBytes:&ratio length:sizeof(float)];
    }];
}

- (NSDictionary *)shadableProperties {
    NSDictionary *properties = @{
        @"environmentMap" : [SCNMaterialProperty materialPropertyWithContents:self.imagePath]
    };
    return properties;
}

@end
