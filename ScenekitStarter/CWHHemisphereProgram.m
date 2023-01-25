//
// CWHHemisphereProgram
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/30/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHHemisphereProgram.h"

@implementation CWHHemisphereProgram

+(BOOL) supportsSecureCoding {
    return YES;
}

-(instancetype)init
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"HemisphereVertex" fragmentFunctionName:@"HemisphereFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        NSColor *skyColor = [NSColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0];
        self.skyColor = skyColor;
        NSColor *groundColor = [NSColor colorWithRed:0.7 green:0.5 blue:0.2 alpha:1.0];
        self.groundColor = groundColor;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> library = [device newDefaultLibrary];

    self = [super initWithLibrary:library vertexFunctionName:@"HemisphereVertex" fragmentFunctionName:@"HemisphereFragment"];

    if ( self != nil )
    {
        self.delegate = self;

        [self bindBuffers];

        self.skyColor =[decoder decodeObjectOfClass:[NSColor class] forKey:@"skyColor"];
        self.groundColor  = [decoder decodeObjectOfClass:[NSColor class] forKey:@"groundColor"];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_skyColor forKey:@"skyColor"];
    [encoder encodeObject:_groundColor forKey:@"groundColor"];
}

- (void)bindBuffers {
    SCNBufferBindingBlock lightBlock = ^(id<SCNBufferStream> buffer, SCNNode *node, id<SCNShadable> shadable, SCNRenderer *renderer)
    {
        struct LightConstants {
            float position[3];
            float skyColor[3];
            float groundColor[3];
        } light;

        light.position[0] = self.lightPosition.x;
        light.position[1] = self.lightPosition.y;
        light.position[2] = self.lightPosition.z;

        if (self.skyColor) {
            light.skyColor[0] = self.skyColor.redComponent;
            light.skyColor[1] = self.skyColor.greenComponent;
            light.skyColor[2] = self.skyColor.blueComponent;
        }

        if (self.groundColor) {
            light.groundColor[0] = self.groundColor.redComponent;
            light.groundColor[1] = self.groundColor.greenComponent;
            light.groundColor[2] = self.groundColor.blueComponent;
        }

        [buffer writeBytes:&light length:sizeof(light)];
    };

    [self handleBindingOfBufferNamed:@"light" frequency:SCNBufferFrequencyPerFrame usingBlock:lightBlock];
}

#pragma mark -  SCNProgramDelegate Protocol Methods

- (void)program:(SCNProgram*)program handleError:(NSError*)error {
    // Log the shader compilation error
    NSLog(@"SceneKit compilation error: %@", error);
}

@end
