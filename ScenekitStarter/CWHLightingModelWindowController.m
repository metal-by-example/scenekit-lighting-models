//
//  CWHLightingModelWindowController.m
//  ScenekitStarter
//
//  Created by Dale Bradshaw on 8/1/14.
//  Copyright (c) 2014 Creative Workflow Hacks. All rights reserved.
//

#import "CWHLightingModelWindowController.h"
#import "CWHLightingViewController.h"
#import "CWHParameterViewController.h"

@interface CWHLightingModelWindowController ()
-(void)saveShaderValues;
@end

@implementation CWHLightingModelWindowController

- (void)awakeFromNib
{
    self.lightingParameterState = FALSE;
    [self updateLightingModel:self.lightingModelPopupButton];
}

-(void)parameterViewWillClose {
    self.lightingParameterState = FALSE;
    [self saveShaderValues];
}

-(void)updateProgram:(SCNProgram *)program shadableProperties:(NSDictionary<NSString *, SCNMaterialProperty *> *)properties;
{
    self.currentProgram = program;

    SCNNode *shadedNode = self.lightingViewController.geometryNode;

    SCNMaterial *programMaterial = [SCNMaterial material];
    programMaterial.program = program;
    for (NSString *key in properties) {
        [programMaterial setValue:properties[key] forKey:key];
    }
    shadedNode.geometry.materials = @[programMaterial];
}

-(CWHParameterViewController *)parameterViewControllerForCurrentProgram
{
    NSString *strippedString = [self.currentLightingModel stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *programString = [NSString stringWithFormat:@"CWH%@ParameterViewController", strippedString];
    NSString *nibString = [NSString stringWithFormat:@"%@ParameterView", strippedString];

    Class parameterViewControllerClass = NSClassFromString(programString);
    CWHParameterViewController *parameterViewController = nil;
    if (parameterViewControllerClass) {
        parameterViewController = [[parameterViewControllerClass alloc]
                                   initWithNibName:nibString bundle:nil];
    }
    
    parameterViewController.program = self.currentProgram;
    
    return parameterViewController;
}

-(IBAction)showInputParameters:(id)sender
{
    if(self.lightingParameterState == FALSE){
        CWHParameterViewController *parameterViewController = [self parameterViewControllerForCurrentProgram];

        if (parameterViewController) {
            [self.lightingViewController presentViewController:parameterViewController
                                       asPopoverRelativeToRect:self.parameterToolbarItem.view.bounds
                                                        ofView:self.parameterToolbarItem.view
                                                 preferredEdge:NSMaxYEdge
                                                      behavior:NSPopoverBehaviorTransient];

            parameterViewController.delegate = self;
            self.lightingParameterState = TRUE;
        }
    
    }else{
        self.lightingParameterState = FALSE;
    }

}

-(void)saveShaderValues
{
    NSError *error = nil;
    if(self.currentProgram) {
        NSString *className = NSStringFromClass([self.currentProgram class]);
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.currentProgram requiringSecureCoding:YES error:&error];
        if (data) {
            [[NSUserDefaults standardUserDefaults] setObject:data forKey:className];
        } else {
            NSLog(@"Encountered error when serializing shader program: %@", error.localizedDescription);
        }
    }
}

-(SCNProgram *)programForLightingModel:(NSString *)lightingModel
{
    NSString *strippedString = [lightingModel stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *programString = [NSString stringWithFormat:@"CWH%@Program", strippedString];
    Class programClass = NSClassFromString(programString);

    SCNProgram *program = nil;
    //unarchive here if we've changed some parameters
    NSData *programData = [[NSUserDefaults standardUserDefaults] objectForKey:programString];
    if(programData){
        NSError *error = nil;
        program = [NSKeyedUnarchiver unarchivedObjectOfClass:programClass fromData:programData error:&error];
        if (program == nil) {
            NSLog(@"Encountered error when deserializing shader program: %@", error.localizedDescription);
        }
    } else if (programClass) {
        program = (SCNProgram *)[programClass program];
    }
    
    return program;
}

- (IBAction)updateLightingModel:(id)sender {
    NSString *updatedModel = [sender titleOfSelectedItem];

    if(![self.currentLightingModel isEqualToString:updatedModel]){
        CWHLightingProgram *program = (CWHLightingProgram *)[self programForLightingModel:updatedModel];
        NSAssert([program isKindOfClass:[CWHLightingProgram class]],
                 @"Program for lighting model is expected to be an instance of a subclass of CWHLightingProgram");
        NSDictionary *properties = program.shadableProperties;
        [self updateProgram:program shadableProperties:properties];
        self.currentLightingModel = updatedModel;
    }
}

@end
