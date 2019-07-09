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
                    case 0:
                    {
                        [self.thermalStateImage setTintColor:[UIColor blueColor]];
                        break;
                    }
                        
                    case 1:
                    {
                        [self.thermalStateImage setTintColor:[UIColor greenColor]];
                        break;
                    }
                        
                    case 2:
                    {
                        [self.thermalStateImage setTintColor:[UIColor yellowColor]];
                        break;
                    }
                        
                    case 3:
                    {
                        [self.thermalStateImage setTintColor:[UIColor redColor]];
                        break;
                    }
                        
                    default:
                        break;
                }
            });
        } else
        if ([[obj allKeys][0] isEqualToString:@"UIDeviceBatteryStateDidChangeNotification"])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch ([[obj objectForKey:[obj allKeys][0]] unsignedIntegerValue]) {
                    case 0:
                    {
                        [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                        [self.batteryStateImage setTintColor:[UIColor grayColor]];
                        break;
                    }
                        
                    case 1:
                    {
                        [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.slash.fill"]];
                        [self.batteryStateImage setTintColor:[UIColor redColor]];
                        break;
                    }
                        
                    case 2:
                    {
                        [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt"]];
                        [self.batteryStateImage setTintColor:[UIColor blueColor]];
                        break;
                    }
                        
                    case 3:
                    {
                        [self.batteryStateImage setImage:[UIImage systemImageNamed:@"bolt.fill"]];
                        [self.batteryStateImage setTintColor:[UIColor greenColor]];
                        break;
                    }
                        
                    default:
                        break;
                }
            });
        }
    }];
}

@end



