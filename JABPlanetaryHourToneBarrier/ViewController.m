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
#import "GraphView.h"

@import QuartzCore;
@import CoreGraphics;

@interface ViewController ()
{
    CAShapeLayer *pathLayerChannelR;
    CAShapeLayer *pathLayerChannelL;
    BOOL wasPlaying;
}

@property (weak, nonatomic) IBOutlet UIImageView *activationImageView;
@property (weak, nonatomic) IBOutlet UIImageView *reachabilityImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thermometerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryLevelImageView;
//@property (weak, nonatomic) IBOutlet UIImageView *playButton;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIImageView *heartRateImage;
@property (weak, nonatomic) IBOutlet GraphView *graphView;

@property (assign) id toneBarrierPlayingObserver;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // HealthKit
    //        if ([HKHealthStore isHealthDataAvailable]) {
    //            [self updateHeartRateMonitorStatus:HeartRateMonitorDataAvailable];
    //            HKHealthStore *healthStore = [HKHealthStore new];
    //            NSSet *objectTypes = [NSSet setWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]]];
    //            [healthStore requestAuthorizationToShareTypes:objectTypes readTypes:objectTypes completion:^(BOOL success, NSError * _Nullable error) {
    //                if (!success) {
    //                    [self updateHeartRateMonitorStatus:HeartRateMonitorPermissionGranted];
    //                    NSLog(@"Unable to access healthkit data: %@", error.description);
    //                } else {
    //                    [self updateHeartRateMonitorStatus:HeartRateMonitorPermissionDenied];
    //                    HKHeartbeatSeriesBuilder *heartRateSeriesBuilder = [[HKHeartbeatSeriesBuilder alloc] initWithHealthStore:healthStore device:[HKDevice localDevice] startDate:[NSDate date]];
    //                    [heartRateSeriesBuilder addHeartbeatWithTimeIntervalSinceSeriesStartDate:180 precededByGap:FALSE completion:^(BOOL success, NSError * _Nullable error) {
    //
    //                    }];
    //                    [heartRateSeriesBuilder finishSeriesWithCompletion:^(HKHeartbeatSeriesSample * _Nullable heartbeatSeries, NSError * _Nullable error) {
    //    //                    NSLog(@"%@", [heartbeatSeries );
    //                    }];
    //
    //                }
    //            }];
    //        } else {
    //            [self updateHeartRateMonitorStatus:HeartRateMonitorDataUnavailable];
    //        }
    //
    //    pathLayerChannelR = [CAShapeLayer new];
    //    [pathLayerChannelR setFrame:self.view.layer.frame];
    //    [pathLayerChannelR setBorderColor:[UIColor redColor].CGColor];
    //    [pathLayerChannelR setBorderWidth:0.25];
    //    [self.view.layer addSublayer:pathLayerChannelR];
    //    pathLayerChannelL = [CAShapeLayer new];
    //    [pathLayerChannelL setFrame:self.view.layer.frame];
    //    [pathLayerChannelL setBorderColor:[UIColor redColor].CGColor];
    //    [pathLayerChannelL setBorderWidth:0.25];
    //    [self.view.layer addSublayer:pathLayerChannelL];
    
    ToneGenerator.sharedGenerator.toneWaveRendererDelegate = self;
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] setDeviceStatusInterfaceDelegate:(id<DeviceStatusInterfaceDelegate>)self];
    [self setupDeviceMonitoring];
    [self activateWatchConnectivitySession];
    [self addStatusObservers];
    
}

typedef NS_ENUM(NSUInteger, HeartRateMonitorStatus) {
    HeartRateMonitorPermissionDenied,
    HeartRateMonitorPermissionGranted,
    HeartRateMonitorDataUnavailable,
    HeartRateMonitorDataAvailable
    
};

- (void)updateHeartRateMonitorStatus:(HeartRateMonitorStatus)heartRateMonitorStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (heartRateMonitorStatus) {
            case HeartRateMonitorPermissionDenied:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.fill"]];
                [self.heartRateImage setTintColor:[UIColor darkGrayColor]];
                break;
            }
                
            case HeartRateMonitorPermissionGranted:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.fill"]];
                [self.heartRateImage setTintColor:[UIColor redColor]];
                break;
            }
                
            case HeartRateMonitorDataUnavailable:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.slash"]];
                [self.heartRateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            case HeartRateMonitorDataAvailable:
            {
                [self.heartRateImage setImage:[UIImage imageNamed:@"heart.fill"]];
                [self.heartRateImage setTintColor:[UIColor greenColor]];
                break;
            }
                
            default:
                break;
        }
    });
}

float scaleBetween(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}


static void (^drawPathToChannelPathLayer)(CAShapeLayer *, UIBezierPath *, UIColor *) = ^(CAShapeLayer *channelPathLayer, UIBezierPath *path, UIColor *hue)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        channelPathLayer.path = path.CGPath;
        channelPathLayer.lineWidth = 3;
        channelPathLayer.fillColor = [UIColor clearColor].CGColor;
        //        float hue = scaleBetween(frequency, 0.0, 1.0, 500, 4000);
        channelPathLayer.strokeColor = hue.CGColor;
        channelPathLayer.strokeStart = 0;
        channelPathLayer.strokeEnd = 0; // <<
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        animation.fromValue = 0;
        animation.toValue = @1;
        animation.duration = 3;
        [channelPathLayer addAnimation:animation forKey:@"strokeEnd"];
    });
};


- (void)drawFrequency:(double)frequency amplitude:(double)amplitude channel:(StereoChannels)channel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.graphView drawFrequency:frequency amplitude:amplitude];
        [self.graphView setNeedsDisplay];
    });
}

//- (void)drawFrequency:(double)frequency amplitude:(double)amplitude channel:(StereoChannels)channel
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGFloat centerY = (channel == StereoChannelR)
//        ? CGRectGetMidY(self->pathLayerChannelR.frame) / 2.0
//        : CGRectGetMidY(self->pathLayerChannelL.frame) + (CGRectGetMidY(self->pathLayerChannelR.frame) / 2.0);
//        CGFloat step  = frequency / CGRectGetWidth((channel == StereoChannelR) ? self->pathLayerChannelR.frame : self->pathLayerChannelL.frame);
//        CGFloat point = CGRectGetMinX((channel == StereoChannelR) ? self->pathLayerChannelR.frame : self->pathLayerChannelL.frame);
//
//        UIBezierPath *path = [UIBezierPath new];
//        CGPoint left_center = CGPointMake(0, centerY);
//        [path moveToPoint:left_center]; //CGPointMake(CGRectGetMinX(self->pathLayerChannelR.frame), CGRectGetMidY(self->pathLayerChannelR.frame))];
//
////        do
////        {
////            CGFloat pixel = pow(scaleBetween(point, 0.0, 1.0, CGRectGetMinX((channel == StereoChannelR) ? self->pathLayerChannelR.frame : self->pathLayerChannelL.frame), CGRectGetWidth((channel == StereoChannelR) ? self->pathLayerChannelR.frame : self->pathLayerChannelL.frame)), amplitude);
////            CGFloat x = point * pixel;
////            CGFloat y = point;
//        NSUInteger x = 0;
//        do {
//            UIBezierPath *subpath = [UIBezierPath new];
//            [subpath moveToPoint:CGPointMake(x, pow(x, 2.0))];
//            [subpath addLineToPoint:CGPointMake(x, pow(x, 2.0))];
//            [path appendPath:subpath];
//            x++;
//        } while (x < CGRectGetWidth(self->pathLayerChannelR.frame));// (int x = 0 /*CGRectGetMinX(self->pathLayerChannelR.frame)*/; x < CGRectGetWidth(self->pathLayerChannelR.frame); x++)
////        {
////
////        }
////            point += step;
////        } while (point < CGRectGetWidth((channel == StereoChannelR) ? self->pathLayerChannelR.frame : self->pathLayerChannelL.frame));
//
//        drawPathToChannelPathLayer((channel == StereoChannelR) ? self->pathLayerChannelR : self->pathLayerChannelL, path, [UIColor colorWithHue:scaleBetween(frequency, 0.0, 1.0, 500, 4000) saturation:1.0 brightness:1.0 alpha:1.0]);
//    });
//}

//- (void)drawFrequency:(double)frequency amplitude:(double)amplitude channel:(StereoChannels)channel
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//    // Draw a sine curve with a fill
//    CGFloat centerY = (channel == StereoChannelR) ? CGRectGetMidY(self->pathLayerChannelR.frame) / 2.0 : CGRectGetMidY(self->pathLayerChannelL.frame) + (CGRectGetMidY(self->pathLayerChannelR.frame) / 2.0);                 // find the vertical center
//    CGFloat steps = frequency;                                                    // Divide the curve into steps
//    CGFloat stepX = (CGRectGetWidth(self.view.frame) / steps) * 2.0;                  // find the horizontal step distance
//    // Make a path
//    UIBezierPath *path = [UIBezierPath new];
//        CGFloat offset_x = (steps * stepX) / 2.0;
//    CGPoint left_center = CGPointMake(0, centerY);
//    [path moveToPoint:left_center];
//    // Loop and draw steps in straight line segments
//    for (int i = 0; i < steps; i++)
//    {
//        CGFloat x = i * stepX;
//        CGFloat y = (sin(i * 0.1) * 40) + centerY;
//        CGPoint point = CGPointMake(x, y);
//        [path addLineToPoint:point];
//    }
//
//        drawPathToChannelPathLayer((channel == StereoChannelR) ? self->pathLayerChannelR : self->pathLayerChannelL, path, [UIColor colorWithHue:scaleBetween(frequency, 0.0, 1.0, 500, 4000) saturation:1.0 brightness:1.0 alpha:1.0]);
//    });
//}

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
    self->_device = [UIDevice currentDevice];
    [self->_device setBatteryMonitoringEnabled:TRUE];
    [self->_device setProximityMonitoringEnabled:TRUE];
}

- (void)addStatusObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus) name:UIDeviceProximityStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDeviceStatus:) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(togglePlayButton) name:@"ToneBarrierPlayingNotification" object:nil];
    
}

- (void)activateWatchConnectivitySession
{
    if ([WCSession isSupported] || !self.watchConnectivitySession)
    {
        self.watchConnectivitySession = [WCSession defaultSession];
        [self.watchConnectivitySession setDelegate:(id<WCSessionDelegate> _Nullable)self];
    }
    [self.watchConnectivitySession activateSession];
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
    [self updateDeviceStatus];
    if (!session.isReachable) [self activateWatchConnectivitySession];
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
    [self updateDeviceStatus];
    replyHandler(deviceStatus(self->_device));
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

static bool(^powerState)(void) = ^bool(void)
{
    return [[NSProcessInfo processInfo] isLowPowerModeEnabled];
};

static NSDictionary<NSString *, id> * (^deviceStatus)(UIDevice *) = ^NSDictionary<NSString *, id> * (UIDevice * device)
{
    NSDictionary<NSString *, id> * status =
    @{@"NSProcessInfoThermalStateDidChangeNotification" : @(thermalState()),
      @"UIDeviceBatteryLevelDidChangeNotification"      : @(batteryLevel(device)),
      @"UIDeviceBatteryStateDidChangeNotification"      : @(batteryState(device)),
      @"NSProcessInfoPowerStateDidChangeNotification"   : @(powerState()),
      @"ToneBarrierPlayingNotification"                 : @([ToneGenerator.sharedGenerator.audioEngine isRunning])};
    
    return status;
};

- (void)updateDeviceStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary<NSString *, id> * status = deviceStatus(self->_device);
        if (self.watchConnectivitySession.reachable) {
            __autoreleasing NSError *error;
            [self.watchConnectivitySession updateApplicationContext:status error:&error];
            //            [watchConnectivitySession sendMessage:status replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
            //            } errorHandler:^(NSError * _Nonnull error) {
            //                NSLog(@"Error sending message: %@", error.description);
            //            }];
        }
        else {
            if (self.watchConnectivitySession.activationState == WCSessionActivationStateActivated)
            {
                __autoreleasing NSError *error;
                [self.watchConnectivitySession updateApplicationContext:status error:&error];
            } else {
                [self.watchConnectivitySession activateSession];
            }
        }
        
        switch (thermalState()) {
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
        
        switch (batteryState(self->_device)) {
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
        
        float level = batteryLevel(self->_device);
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
                } else
                    if (level <= .125)
                    {
                        [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.0"]];
                        [self.batteryLevelImageView setTintColor:[UIColor redColor]];
                        //                        [ToneGenerator.sharedGenerator alarm];
                    }
    });
}

- (void)updateWatchConnectivityStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        WCSessionActivationState activationState = self.watchConnectivitySession.activationState;
        BOOL reachable = self.watchConnectivitySession.isReachable;
        if (activationState != WCSessionActivationStateActivated) [self.watchConnectivitySession activateSession];
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
            {
                [self.activationImageView setTintColor:[UIColor grayColor]];
                break;
            }
        }
        
        [self.reachabilityImageView setTintColor:(reachable) ? [UIColor greenColor] : [UIColor redColor]];
    });
}

// TO-DO: Only send isPlaying after calling start or stop; do not "test" for it
- (IBAction)toggleToneGenerator:(UIButton *)sender {
    NSLog(@"Toggling tone generator...");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [ToneGenerator.sharedGenerator start];
        } else if ([ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [ToneGenerator.sharedGenerator stop];
        }
    });
    [self updateDeviceStatus];
}

- (void)togglePlayButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [self.playButton setImage:[UIImage systemImageNamed:@"stop"] forState:UIControlStateNormal];
        } else if (![ToneGenerator.sharedGenerator.audioEngine isRunning]) {
            [self.playButton setImage:[UIImage systemImageNamed:@"play"] forState:UIControlStateNormal];
        }
    });
}

- (void)handleInterruption:(NSNotification *)notification
{
    [self updateWatchConnectivityStatus];
    [self updateDeviceStatus];
    wasPlaying = [ToneGenerator.sharedGenerator.audioEngine isRunning];
    NSDictionary *userInfo = [notification userInfo];
    NSInteger typeValue = [[userInfo objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)typeValue;
    if (type)
    {
        if (type == AVAudioSessionInterruptionTypeBegan)
        {
            if (wasPlaying) [self toggleToneGenerator:nil];
        } else if (type == AVAudioSessionInterruptionTypeEnded)
            {
//                NSInteger optionsValue = [[userInfo objectForKey:AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
//                AVAudioSessionInterruptionOptions options = (AVAudioSessionInterruptionOptions)optionsValue;
                if (wasPlaying)
                {
                    [self toggleToneGenerator:nil];
                }
            }
    }
}

@end











