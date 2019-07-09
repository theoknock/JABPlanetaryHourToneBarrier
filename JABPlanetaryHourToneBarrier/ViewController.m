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
@property (weak, nonatomic) IBOutlet UIImageView *batteryLevelImageView;
@property (weak, nonatomic) IBOutlet UIImageView *playButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    sampleRate = 44100;
    amplitude = 1.0;
    
    __autoreleasing NSError *categorySessionError;
    [[AVAudioSession sharedInstance] setActive:YES error:&categorySessionError];
    if (!categorySessionError)
    {
        AVAudioSessionCategory sessionCategory = AVAudioSessionCategoryPlayback;
        [[AVAudioSession sharedInstance] setCategory:sessionCategory error:nil];
    }
    __autoreleasing NSError *activateSessionError;
    [[AVAudioSession sharedInstance] setActive:TRUE error:&activateSessionError];
    if (activateSessionError)
        NSLog(@"Error activating audio session: %@", activateSessionError.description);
    
    [self setupDeviceMonitoring];
    [self activateWatchConnectivitySession];
}

float(^sine)(float(^)(void), float(^)(void), float(^)(void)) = ^float(float(^frequency)(void), float(^duration)(void), float(^amplitude)(void))
{
    return amplitude() * sin(2.0 * M_PI * frequency() * duration());
};

float(^frequency)(void) = ^(void)
{
    return (((float)arc4random() / 0x100000000) * (high_bound - low_bound) + low_bound);
};

float(^duration)(void) = ^(void)
{
    return (((float)arc4random() / 0x100000000) * (max_duration - min_duration) + min_duration);
};

float(^amplitude)(void) = ^(void)
{
    return (((float)arc4random() / 0x100000000) * (max_amplitude - min_amplitude) + min_amplitude);
};

OSStatus RenderTone(
                    void                        *inRefCon,
                    AudioUnitRenderActionFlags  *ioActionFlags,
                    const AudioTimeStamp        *inTimeStamp,
                    UInt32                       inBusNumber,
                    UInt32                       inNumberFrames,
                    AudioBufferList             *ioData)

{
    // Fixed amplitude is good enough for our purposes
    //    const double amplitude = 1.0;
    
    // Get the tone parameters out of the view controller
    ViewController *viewController = (__bridge ViewController *)inRefCon;
    double theta                   = viewController->theta;
    double theta_increment         = 2.0 * M_PI * viewController->frequency / viewController->sampleRate;
    
    // This is a monotone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer   = (Float32 *)ioData->mBuffers[channel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * viewController->amplitude;
        
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
            theta -= 2.0 * M_PI;
    }
    
    // Store the theta back in the view controller
    viewController->theta = theta;
    
    return noErr;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
    //    ToneGraphViewController *toneGraphViewController = (__bridge ToneGraphViewController *)inClientData;
    //    toneGraphViewController->alarm = TRUE;
    //    [ToneGraphViewController stop];
}

- (void)createToneUnit
{
    // Configure the search parameters to find the default playback output unit
    // (called the kAudioUnitSubType_RemoteIO on iOS but
    // kAudioUnitSubType_DefaultOutput on Mac OS X)
    AudioComponentDescription defaultOutputDescription;
    defaultOutputDescription.componentType = kAudioUnitType_Output;
    defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    defaultOutputDescription.componentFlags = 0;
    defaultOutputDescription.componentFlagsMask = 0;
    
    // Get the default playback output unit
    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
    NSAssert(defaultOutput, @"Can't find default output");
    
    // Create a new unit based on this that we'll use for output
    OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
    NSAssert1(toneUnit, @"Error creating unit: %hd", err);
    
    // Set our tone rendering function on the unit
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void * _Nullable)(self);
    err = AudioUnitSetProperty(toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
    NSAssert1(err == noErr, @"Error setting callback: %hd", err);
    
    // Set the format to 32 bit, single channel, floating point, linear PCM
    const int four_bytes_per_float = 4;
    const int eight_bits_per_byte = 8;
    AudioStreamBasicDescription streamFormat;
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    streamFormat.mBytesPerPacket = four_bytes_per_float;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = four_bytes_per_float;
    streamFormat.mChannelsPerFrame = 1;
    streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
    err = AudioUnitSetProperty (toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
    NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
}

- (void)start
{
    if (!toneUnit)
    {
        [self createToneUnit];
        // Stop changing parameters on the unit
        OSErr err = AudioUnitInitialize(toneUnit);
        NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
        
        // Start playback
        err = AudioOutputUnitStart(toneUnit);
        NSAssert1(err == noErr, @"Error starting unit: %hd", err);
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
            dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
            dispatch_source_set_event_handler(timer, ^{
                float duration = (((float)arc4random() / 0x100000000) * (max_duration - min_duration) + min_duration);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self->frequency = (((float)arc4random() / 0x100000000) * (high_bound - low_bound) + low_bound);
                    
                });
                self->frequency = (((float)arc4random() / 0x100000000) * (high_bound - low_bound) + low_bound);
                
            });
        });
        
        dispatch_resume(timer);
    } else {
        [self stop];
        [self start];
    }
}

- (void)stop
{
    dispatch_suspend(timer);
    
    AudioOutputUnitStop(toneUnit);
    AudioUnitUninitialize(toneUnit);
    AudioComponentInstanceDispose(toneUnit);
    toneUnit = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    __autoreleasing NSError *deactivateSessionError;
    [[AVAudioSession sharedInstance] setActive:FALSE error:&deactivateSessionError];
    if (deactivateSessionError)
        NSLog(@"Error deactivating audio session: %@", deactivateSessionError.description);
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
    replyHandler(@{@"" : @((toneUnit == nil))});
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
              @{@"UIDeviceBatteryLevelDidChangeNotification"      : @(batteryLevel)},
              @{@"UIDeviceBatteryStateDidChangeNotification"      : @(batteryState)},
              @{@"ToneGeneratorPlaying"                           : @((toneUnit != nil))}]};
    
    __autoreleasing NSError *error;
    [watchConnectivitySession updateApplicationContext:deviceStatus error:&error];
    if (error) NSLog(@"Error updating application context: %@", error.description);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (thermalState) {
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
        if (batteryLevel >= .9)
        {
            [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.100"]];
            [self.batteryLevelImageView setTintColor:[UIColor greenColor]];
        } else
            if (batteryLevel < .9)
            {
                [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.25"]];
                [self.batteryLevelImageView setTintColor:[UIColor yellowColor]];
            } else
                if (batteryLevel <= .25)
                {
                    [self.batteryLevelImageView setImage:[UIImage systemImageNamed:@"battery.0"]];
                    [self.batteryLevelImageView setTintColor:[UIColor redColor]];
                }
    });
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
            {
                [self.activationImageView setTintColor:[UIColor grayColor]];
                break;
            }
        }
        
        [self.reachabilityImageView setTintColor:(reachable) ? [UIColor greenColor] : [UIColor redColor]];
    });
}

- (IBAction)toggleToneGenerator:(UITapGestureRecognizer *)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (toneUnit != nil) {
            [self stop];
            [self.playButton setImage:[UIImage systemImageNamed:@"play"]];
        } else {
            [self start];
            [self.playButton setImage:[UIImage systemImageNamed:@"stop"]];
        }
        [self updateDeviceStatus];
    });
}

@end





