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
- (void)updatePeerDeviceStatusInterface:(NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> *)receivedApplicationContext
{
    [[receivedApplicationContext objectForKey:[receivedApplicationContext allKeys][0]] enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj allKeys][0] isEqualToString:@"NSProcessInfoThermalStateDidChangeNotification"])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch ([[obj objectForKey:[obj allKeys][0]] unsignedIntegerValue]) {
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
            });
        } else
            if ([[obj allKeys][0] isEqualToString:@"UIDeviceBatteryStateDidChangeNotification"])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch ([[obj objectForKey:[obj allKeys][0]] unsignedIntegerValue]) {
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
                });
            } else
                if ([[obj allKeys][0] isEqualToString:@"UIDeviceBatteryLevelDidChangeNotification"])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([[obj objectForKey:[obj allKeys][0]] floatValue] >= .9)
                        {
                            [self.batteryLevelImage setImage:[UIImage systemImageNamed:@"battery.100"]];
                            [self.batteryLevelImage setTintColor:[UIColor greenColor]];
                        } else
                            if ([[obj objectForKey:[obj allKeys][0]] floatValue] < .9)
                            {
                                [self.batteryLevelImage setImage:[UIImage systemImageNamed:@"battery.25"]];
                                [self.batteryLevelImage setTintColor:[UIColor yellowColor]];
                            } else
                                if ([[obj objectForKey:[obj allKeys][0]] floatValue] <= .25)
                                {
                                    [self.batteryLevelImage setImage:[UIImage systemImageNamed:@"battery.0"]];
                                    [self.batteryLevelImage setTintColor:[UIColor redColor]];
                                }
                    });
            } else
                if ([[obj allKeys][0] isEqualToString:@"ToneGeneratorPlaying"])
                {
                    [self.playButton setBackgroundImage:([[obj objectForKey:[obj allKeys][0]] boolValue]) ? [UIImage systemImageNamed:@"stop"] : [UIImage systemImageNamed:@"play"]];
                }
    }];
}

- (IBAction)toggleToneGenerator
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    WCSession *watchConnectivitySession = [(ExtensionDelegate *)[[WKExtension sharedExtension] delegate] watchConnectivitySession];
    if (watchConnectivitySession.isReachable)
    {
        [watchConnectivitySession sendMessage:@{@"ToneGenerator" : @"Toggle"} replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"REPLY %lu", [[replyMessage objectForKey:[replyMessage allKeys][0]] boolValue]);
                
                [self.playButton setBackgroundImage:([[replyMessage objectForKey:[replyMessage allKeys][0]] boolValue]) ? [UIImage systemImageNamed:@"stop"] : [UIImage systemImageNamed:@"play"]];
            });
        } errorHandler:^(NSError * _Nonnull error) {
            
        }];
    }
}

@end





