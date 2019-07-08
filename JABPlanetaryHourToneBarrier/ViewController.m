//
//  ViewController.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    WCSession *watchConnectivitySession;
}

@property (weak, nonatomic) IBOutlet UIImageView *activationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reachabilityImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self activateWatchConnectivitySession];
}

- (void)addStatusObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryStateDidChangeNotification object:nil];
}

- (void)activateWatchConnectivitySession
{
    [self updateWatchConnectivityStatus];
    watchConnectivitySession = [WCSession defaultSession];
    [watchConnectivitySession setDelegate:(id<WCSessionDelegate> _Nullable)self];
    [watchConnectivitySession activateSession];
}

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error
{
    [self updateWatchConnectivityStatus];
    if (activationState != 2) [self activateWatchConnectivitySession];
    else if (activationState == 2) [self updateDeviceStatus];
}

- (void)sessionReachabilityDidChange:(WCSession *)session
{
    [self updateWatchConnectivityStatus];
    if (!session.isReachable) [self activateWatchConnectivitySession];
    else [self updateDeviceStatus];
}

- (void)sessionDidBecomeInactive:(WCSession *)session
{
    [self updateWatchConnectivityStatus];
    [self activateWatchConnectivitySession];
}

- (void)sessionDidDeactivate:(WCSession *)session
{
    [self updateWatchConnectivityStatus];
    [self activateWatchConnectivitySession];
}

- (void)updateDeviceStatus
{
    NSDictionary<NSString *, NSNumber *> * thermalState = @{@"NSProcessInfoThermalStateDidChangeNotification" : @([[NSProcessInfo processInfo] thermalState])};
    NSDictionary<NSString *, NSNumber *> * batteryLevel = @{@"UIDeviceBatteryLevelDidChangeNotification" : @([[UIDevice currentDevice] batteryLevel])};
    NSDictionary<NSString *, NSNumber *> * batteryState = @{@"UIDeviceBatteryStateDidChangeNotification" : @([[UIDevice currentDevice] batteryState])};
    NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> * deviceStatus = @{@"DeviceStatus" : @[thermalState, batteryLevel, batteryState]};
    
    __autoreleasing NSError *error;
    [watchConnectivitySession updateApplicationContext:deviceStatus error:&error];
    if (error) NSLog(@"Error updating application context: %@", error.description);
}

- (void)updateWatchConnectivityStatus
{
    WCSessionActivationState activationState = watchConnectivitySession.activationState;
    BOOL reachable = watchConnectivitySession.isReachable;
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (activationState) {
            case WCSessionActivationStateInactive:
            {
                [self.activationImageView setTintColor:[UIColor grayColor]];
                break;
            }
                
            case WCSessionActivationStateNotActivated:
            {
                [self.activationImageView setTintColor:[UIColor redColor]];
                break;
            }
                
            case WCSessionActivationStateActivated:
            {
                [self.activationImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
                break;
        }
        
        [self.reachabilityImageView setTintColor:(reachable) ? [UIColor greenColor] : [UIColor redColor]];
    });
}

@end
