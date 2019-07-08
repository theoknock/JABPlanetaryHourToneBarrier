//
//  InterfaceController.m
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "InterfaceController.h"
#import "ExtensionDelegate.h"

@interface InterfaceController ()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    [(ExtensionDelegate *)[[WKExtension sharedExtension] delegate] setWatchConnectivityStatusInterfaceDelegate:(id<WatchConnectivityStatusInterfaceProtocol>)self];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)updateStatusInterfaceForActivationState:(WCSessionActivationState)activationState reachability:(BOOL)reachable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (activationState) {
            case WCSessionActivationStateInactive:
            {
                [self.activationImage setTintColor:[UIColor grayColor]];
                break;
            }
                
            case WCSessionActivationStateNotActivated:
            {
                [self.activationImage setTintColor:[UIColor redColor]];
                break;
            }
                
            case WCSessionActivationStateActivated:
            {
                [self.activationImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
                break;
        }
        
        [self.reachabilityImage setTintColor:(reachable) ? [UIColor greenColor] : [UIColor redColor]];
    });
}

@end



