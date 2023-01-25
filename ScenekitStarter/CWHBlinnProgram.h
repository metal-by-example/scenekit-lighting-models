//
//  CWHBlinnProgram.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/29/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "CWHLightingProgram.h"

@interface CWHBlinnProgram : CWHLightingProgram <SCNProgramDelegate, NSSecureCoding>

@property (nonatomic, strong) NSColor *lightColor;
@property (nonatomic, strong) NSColor *ambientColor;

@end
