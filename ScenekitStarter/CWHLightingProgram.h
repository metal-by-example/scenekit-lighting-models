//
//  CWHLightingProgram.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 9/9/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface CWHLightingProgram : SCNProgram<SCNProgramDelegate>

- (id)initWithProgram:(NSString *)program;

- (instancetype)initWithLibrary:(id<MTLLibrary>)library
             vertexFunctionName:(NSString *)vertexFunctionName
           fragmentFunctionName:(NSString *)fragmentFunctionName;

@property (nonatomic, readonly, copy) NSDictionary<NSString *, id> *shadableProperties;

@property (nonatomic, assign) SCNVector3 lightPosition;

@end
