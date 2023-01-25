//
//  CWHEnvMapProgram.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 8/25/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "CWHLightingProgram.h"

@interface CWHEnvMapProgram : CWHLightingProgram <SCNProgramDelegate, NSSecureCoding>

@property (strong) NSColor *diffuseColor;
@property (strong) NSColor *ambientColor;
@property (assign) double ratio;
@property (strong) NSString *imagePath;

@end
