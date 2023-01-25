//
//  CWHLUTSkinProgram.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 7/31/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "CWHLightingProgram.h"

@interface CWHLUTSkinProgram : CWHLightingProgram <SCNProgramDelegate, NSSecureCoding>

@property (strong) NSColor *diffuseColor;
@property (strong) NSColor *specularColor;
@property (strong) NSColor *scatterColor;
@property (assign) double wrap;
@property (assign) double scatterWidth;
@property (assign) double shininess;

@end
