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
    UIDevice *device;
}

@property (weak, nonatomic) IBOutlet UIImageView *activationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reachabilityImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thermometerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupDeviceMonitoring];
    [self activateWatchConnectivitySession];
}

- (void)setupDeviceMonitoring
{
    device = [UIDevice currentDevice];
    [device setBatteryMonitoringEnabled:TRUE];
    [device setProximityMonitoringEnabled:TRUE];
    [self updateDeviceStatus];
}

- (void)addStatusObservers
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceProximityStateDidChangeNotification object:nil];
}

- (void)activateWatchConnectivitySession
{
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

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext
{
    [self updateDeviceStatus];
}

- (void)updateDeviceStatus
{
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    UIDeviceBatteryState batteryState = [[UIDevice currentDevice] batteryState];
    float batteryLevel = [[UIDevice currentDevice] batteryLevel];
    NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> * deviceStatus =
  @{@"DeviceStatus" :
  @[
  @{@"NSProcessInfoThermalStateDidChangeNotification" : @(thermalState)},
  @{@"UIDeviceBatteryLevelDidChangeNotification" : @(batteryLevel)},
  @{@"UIDeviceBatteryStateDidChangeNotification" : @(batteryState)}]};
    
    __autoreleasing NSError *error;
    [watchConnectivitySession updateApplicationContext:deviceStatus error:&error];
    if (error) NSLog(@"Error updating application context: %@", error.description);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (thermalState) {
            case NSProcessInfoThermalStateNominal:
            {
                [self.thermometerImageView setTintColor:[UIColor blueColor]];
                break;
            }
                
            case NSProcessInfoThermalStateFair:
            {
                [self.thermometerImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            case NSProcessInfoThermalStateSerious:
            {
                [self.thermometerImageView setTintColor:[UIColor yellowColor]];
                break;
            }
                
            case NSProcessInfoThermalStateCritical:
            {
                [self.thermometerImageView setTintColor:[UIColor redColor]];
                break;
            }
                
            default:
                break;
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (batteryState) {
            case UIDeviceBatteryStateUnknown:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                [self.batteryImageView setTintColor:[UIColor grayColor]];
                break;
            }
                
            case UIDeviceBatteryStateUnplugged:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.slash.fill"]];
                [self.batteryImageView setTintColor:[UIColor redColor]];
                break;
            }
                
            case UIDeviceBatteryStateCharging:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt"]];
                [self.batteryImageView setTintColor:[UIColor blueColor]];
                break;
            }
                
            case UIDeviceBatteryStateFull:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.fill"]];
                [self.batteryImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
            {
                [self.batteryImageView setImage:[UIImage systemImageNamed:@"bolt.slash"]];
                [self.batteryImageView setTintColor:[UIColor grayColor]];
                break;
            }
        }
    });
    
    NSLog(@"%lu %f", batteryState, batteryLevel);
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
