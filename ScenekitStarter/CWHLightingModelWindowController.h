//
//  CWHLightingModelWindowController.h
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 8/1/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CWHPhongPointLightParameterViewController.h"
@class CWHLightingViewController;

@interface CWHLightingModelWindowController : NSWindowController<CWHParameterViewProtocol>
{
    __weak IBOutlet NSView *targetView;
}

@property (weak) IBOutlet NSMenu *lightingModelMenu;
@property (weak) IBOutlet NSPopUpButton *lightingModelPopupButton;
@property (weak) IBOutlet NSToolbarItem *parameterToolbarItem;
-(IBAction)showInputParameters:(id)sender;
-(IBAction)updateLightingModel:(id)sender;

@property (strong) IBOutlet CWHLightingViewController *lightingViewController;
@property (assign) BOOL lightingParameterState;
@property (strong) NSString *currentLightingModel;
@property (strong) SCNProgram *currentProgram;

@end
