//
//  InterfaceController.m
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "InterfaceController.h"
#import "ExtensionDelegate.h"
#import "WatchToneGenerator.h"


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
            {
                [self.activationImage setTintColor:[UIColor grayColor]];
                break;
            }
        }
        
        [self.reachabilityImage setTintColor:(reachable) ? [UIColor greenColor] : [UIColor redColor]];
    });
}

- (void)updatePeerDeviceStatusInterface:(NSDictionary<NSString *, id> *)receivedApplicationContext
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger thermalState = [[receivedApplicationContext objectForKey:@"NSProcessInfoThermalStateDidChangeNotification"] unsignedIntegerValue];
        switch (thermalState) {
            case NSProcessInfoThermalStateNominal:
            {
                [self.thermalStateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            case NSProcessInfoThermalStateFair:
            {
                [self.thermalStateImage setTintColor:[UIColor yellowColor]];
                break;
            }
                
            case NSProcessInfoThermalStateSerious:
            {
                [self.thermalStateImage setTintColor:[UIColor redColor]];
                break;
            }
                
            case NSProcessInfoThermalStateCritical:
            {
                [self.thermalStateImage setTintColor:[UIColor whiteColor]];
                break;
            }
                
            default:
            {
                [self.thermalStateImage setTintColor:[UIColor grayColor]];
            }
                break;
        }
        
        NSUInteger batteryState = [[receivedApplicationContext objectForKey:@"UIDeviceBatteryStateDidChangeNotification"] unsignedIntegerValue];
        switch (batteryState) {
            case WKInterfaceDeviceBatteryStateUnknown:
            {
                [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                [self.batteryStateImage setTintColor:[UIColor grayColor]];
                break;
            }
                
            case WKInterfaceDeviceBatteryStateUnplugged:
            {
                [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.slash.fill"]];
                [self.batteryStateImage setTintColor:[UIColor redColor]];
                break;
            }
                
            case WKInterfaceDeviceBatteryStateCharging:
            {
                [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt"]];
                [self.batteryStateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            case WKInterfaceDeviceBatteryStateFull:
            {
                [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.fill"]];
                [self.batteryStateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
            {
                [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                [self.batteryStateImage setTintColor:[UIColor grayColor]];
                break;
            }
        }
        
        float batteryLevel =  [[receivedApplicationContext objectForKey:@"UIDeviceBatteryLevelDidChangeNotification"] floatValue];
        if (batteryLevel <= 1.0 && batteryLevel > .66)
        {
            [self.batteryLevelImage setImage:[UIImage systemImageNamed:@"battery.100"]];
            [self.batteryLevelImage setTintColor:[UIColor greenColor]];
        } else {
            if (batteryLevel <= .66 && batteryLevel > .33)
            {
                [self.batteryLevelImage setImage:[UIImage systemImageNamed:@"battery.25"]];
                [self.batteryLevelImage setTintColor:[UIColor yellowColor]];
            } else {
                if (batteryLevel <= .33)
                {
                    [self.batteryLevelImage setImage:[UIImage systemImageNamed:@"battery.0"]];
                    [self.batteryLevelImage setTintColor:[UIColor redColor]];
                }
            }
        }
        
        NSLog(@"Tone barrier %@ playing", ([receivedApplicationContext objectForKey:@"ToneGeneratorDidPlay"]) ? @"is" : @"is not");
        [self.playButton setBackgroundImage:([receivedApplicationContext objectForKey:@"ToneGeneratorDidPlay"]) ? [UIImage systemImageNamed:@"play"] : [UIImage systemImageNamed:@"stop"]];
    });
}

- (IBAction)toggleToneGenerator
{
    WCSession *watchConnectivitySession = [(ExtensionDelegate *)[[WKExtension sharedExtension] delegate] watchConnectivitySession];
    if (watchConnectivitySession.isReachable)
    {
        [watchConnectivitySession sendMessage:@{@"ToneGenerator" : @"Toggle"} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
//            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePeerDeviceStatusInterface:replyMessage];
//            });
        } errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"Tone generator activation error: %@", error.description);
        }];
    }
}

@end






