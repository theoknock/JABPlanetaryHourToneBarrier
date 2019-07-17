//
//  ViewController.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ViewController.h"
#import "ToneGenerator.h"
#import "AppDelegate.h"

@interface ViewController ()
{
    WCSession *watchConnectivitySession;
    UIDevice *device;
}

@property (weak, nonatomic) IBOutlet UIImageView *activationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reachabilityImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thermometerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryLevelImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] setDeviceStatusInterfaceDelegate:(id<DeviceStatusInterfaceDelegate>)self];
    [self setupDeviceMonitoring];
    [self activateWatchConnectivitySession];
    [self addStatusObservers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)setupDeviceMonitoring
{
    device = [UIDevice currentDevice];
    [device setBatteryMonitoringEnabled:TRUE];
    [device setProximityMonitoringEnabled:TRUE];
}

- (void)addStatusObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceProximityStateDidChangeNotification object:nil];
}

- (void)activateWatchConnectivitySession
{
    if ([WCSession isSupported] || !watchConnectivitySession)
    {
        watchConnectivitySession = [WCSession defaultSession];
        [watchConnectivitySession setDelegate:(id<WCSessionDelegate> _Nullable)self];
    }
    [watchConnectivitySession activateSession];
}

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error
{
    if (activationState != WCSessionActivationStateActivated) [self activateWatchConnectivitySession];
    [self updateWatchConnectivityStatus];
    [self updateDeviceStatus];
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
    [self toggleToneGenerator:nil];
    [self updateDeviceStatus];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message replyHandler:(void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
    [self toggleToneGenerator:nil];
    replyHandler(@{@"" : @((ToneGenerator.sharedGenerator.timer == nil))});
}

static NSProcessInfoThermalState(^thermalState)(void) = ^NSProcessInfoThermalState(void)
{
    NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
    return thermalState;
};

static UIDeviceBatteryState(^batteryState)(UIDevice *) = ^UIDeviceBatteryState(UIDevice * device)
{
    UIDeviceBatteryState batteryState = [device batteryState];
    return batteryState;
};

static float(^batteryLevel)(UIDevice *) = ^float(UIDevice * device)
{
    float batteryLevel = [device batteryLevel];
    return batteryLevel;
};

static NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> *(^deviceStatus)(UIDevice *) = ^NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> *(UIDevice * device)
{
    NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> * status =
    @{@"DeviceStatus" :
          @[
              @{@"NSProcessInfoThermalStateDidChangeNotification" : @(thermalState())},
              @{@"UIDeviceBatteryLevelDidChangeNotification"      : @(batteryLevel(device))},
              @{@"UIDeviceBatteryStateDidChangeNotification"      : @(batteryState(device))},
              @{@"ToneGeneratorPlaying"                           : @((ToneGenerator.sharedGenerator.timer != nil))}]};
    
    return status;
};

- (void)updateDeviceStatus
{
    NSDictionary<NSString *, NSArray<NSDictionary<NSString *, NSNumber *> *> *> * status = deviceStatus(device);
    
    __autoreleasing NSError *error;
    [watchConnectivitySession updateApplicationContext:status error:&error];
    
    if (error)
    {
        NSLog(@"Error updating application context: %@", error.description);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch ([(NSNumber *)[status objectForKey:@"NSProcessInfoThermalStateDidChangeNotification"] integerValue]) {
                case NSProcessInfoThermalStateNominal:
                {
                    [self.thermometerImageView setTintColor:[UIColor greenColor]];
                    break;
                }
                    
                case NSProcessInfoThermalStateFair:
                {
                    [self.thermometerImageView setTintColor:[UIColor yellowColor]];
                    break;
                }
                    
                case NSProcessInfoThermalStateSerious:
                {
                    [self.thermometerImageView setTintColor:[UIColor redColor]];
                    break;
                }
                    
                case NSProcessInfoThermalStateCritical:
                {
                    [self.thermometerImageView setTintColor:[UIColor whiteColor]];
                    break;
                }
                    
                default:
                {
                    [self.thermometerImageView setTintColor:[UIColor grayColor]];
                }
                    break;
            }
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (batteryState(self->device)) {
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
                    [self.batteryImageView setTintColor:[UIColor greenColor]];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            float level = batteryLevel(self->device);
            if (level <= 1.0 || level > .66)
            {
                [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.100"]];
                [self.batteryLevelImageView setTintColor:[UIColor greenColor]];
            } else
                if (level <= .66 || level > .33)
                {
                    [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.25"]];
                    [self.batteryLevelImageView setTintColor:[UIColor yellowColor]];
                } else
                    if (level <= .33)
                    {
                        [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.0"]];
                        [self.batteryLevelImageView setTintColor:[UIColor redColor]];
                    }
        });
    }
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
                [self->watchConnectivitySession activateSession];
                break;
            }
                
            case WCSessionActivationStateNotActivated:
            {
                [self.activationImageView setTintColor:[UIColor redColor]];
                [self->watchConnectivitySession activateSession];
                break;
            }
                
            case WCSessionActivationStateActivated:
            {
                
                [self.activationImageView setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
            {
                [self.activationImageView setTintColor:[UIColor grayColor]];
                [self->watchConnectivitySession activateSession];
                break;
            }
        }
        
        [self.reachabilityImageView setTintColor:(reachable) ? [UIColor greenColor] : [UIColor redColor]];
    });
}

- (IBAction)toggleToneGenerator:(UITapGestureRecognizer *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:2.0 animations:^{
            UIImage *bold_symbol = [[self.playButton image] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightBold]];
            [self.playButton setImage:bold_symbol];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:2.0 animations:^{
                UIImage *regular_symbol = [[self.playButton image] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightRegular]];
                [self.playButton setImage:regular_symbol];
            } completion:^(BOOL finished) {
                if ([ToneGenerator.sharedGenerator timer] == nil) {
                    [ToneGenerator.sharedGenerator start];
                    [self.playButton setImage:[UIImage systemImageNamed:@"stop"]];
                } else if ([ToneGenerator.sharedGenerator timer] != nil) {
                    [ToneGenerator.sharedGenerator stop];
                    [self.playButton setImage:[UIImage systemImageNamed:@"play"]];
                }
            }];
        }];
    });
}

- (void)handleInterruption:(NSNotification *)notification
{
    [self updateWatchConnectivityStatus];
    [self updateDeviceStatus];
    
    BOOL wasPlaying = FALSE;
    NSDictionary *userInfo = [notification userInfo];
    NSInteger typeValue = [[userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)typeValue;
    if (type)
    {
        if (type == AVAudioSessionInterruptionTypeBegan)
        {
            if (ToneGenerator.sharedGenerator.timer != nil)
            {
                [self toggleToneGenerator:nil];
                wasPlaying = TRUE;
            }
        } else
            if (type == AVAudioSessionInterruptionTypeEnded)
            {
                NSInteger optionsValue = [[userInfo objectForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
                AVAudioSessionInterruptionOptions options = (AVAudioSessionInterruptionOptions)optionsValue;
                if (options == AVAudioSessionInterruptionOptionShouldResume && wasPlaying)
                {
                    [self toggleToneGenerator:nil];
                }
            }
    }
}

@end









