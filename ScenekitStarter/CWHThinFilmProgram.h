//
//  CWHThinFilmProgram.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 8/28/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import "CWHLightingProgram.h"

@interface CWHThinFilmProgram : CWHLightingProgram <SCNProgramDelegate, NSSecureCoding>

@property (assign) double filmDepth;
@property (strong) NSColor *diffuseColor;
@property (strong) NSString *imagePath;

@end
