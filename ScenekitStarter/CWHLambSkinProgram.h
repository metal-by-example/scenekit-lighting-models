//
//  CWHLambSkinProgram.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/31/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "CWHLightingProgram.h"

@interface CWHLambSkinProgram : CWHLightingProgram <SCNProgramDelegate, NSSecureCoding>

@property (strong) NSColor *diffuseColor;
@property (strong) NSColor *ambientColor;
@property (strong) NSColor *subColor;
@property (assign) double rolloff;

@end
