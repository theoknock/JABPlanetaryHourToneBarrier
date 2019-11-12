//
//  WatchToneGenerator.m
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/31/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

/*
 #import <Foundation/Foundation.h>
 #import <AVFoundation/AVFoundation.h>

 NS_ASSUME_NONNULL_BEGIN

 @interface WatchToneGenerator : NSObject

 @property (nonatomic, readonly) AVAudioEngine *audioEngine;

 + (nonnull WatchToneGenerator *)sharedGenerator;

 @property (nonatomic, strong) dispatch_source_t timer;

 - (void)start;
 //- (void)scheduleStart:(NSDate *)start duration:(NSTimeInterval)duration;
 - (void)stop;

 @end

 NS_ASSUME_NONNULL_END

 */

#import "WatchToneGenerator.h"


//static const AVAudioFrameCount kSamplesPerBuffer = 1024;
static const float high_frequency = 4000.0f;
static const float low_frequency = 500.0f;

@interface WatchToneGenerator ()

@property (nonatomic, readonly) AVAudioMixerNode *mixerNode;
@property (nonatomic, readonly) AVAudioPCMBuffer* pcmBufferOne;
@property (nonatomic, readonly) AVAudioPCMBuffer* pcmBufferTwo;
@property (nonatomic, readonly) AVAudioSession *audioSession;


@end

@implementation WatchToneGenerator

- (NSUInteger)greatestCommonDivisor:(NSUInteger)firstValue secondValue:(NSUInteger)secondValue
{
    if (firstValue == 0 && secondValue == 0)
        return 1;
    
    NSUInteger r;
    while(secondValue)
    {
        r = firstValue % secondValue;
        firstValue = secondValue;
        secondValue = r;
    }
    return firstValue;
}

static WatchToneGenerator *sharedGenerator = NULL;
+ (nonnull WatchToneGenerator *)sharedGenerator
{
    static dispatch_once_t onceSecurePredicate;
    dispatch_once(&onceSecurePredicate,^
                  {
        if (!sharedGenerator)
        {
            sharedGenerator = [[self alloc] init];
        }
    });
    
    return sharedGenerator;
}

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _audioEngine = [[AVAudioEngine alloc] init];
        
        _mixerNode = _audioEngine.mainMixerNode;
        
        _playerOneNode = [[AVAudioPlayerNode alloc] init];
        [_audioEngine attachNode:_playerOneNode];
        
        [_audioEngine connect:_playerOneNode to:_mixerNode format:[_playerOneNode outputFormatForBus:0]];
        
        _playerTwoNode = [[AVAudioPlayerNode alloc] init];
        [_audioEngine attachNode:_playerTwoNode];
        
        [_audioEngine connect:_playerTwoNode to:_mixerNode format:[_playerTwoNode outputFormatForBus:0]];
        
        _audioSession = [AVAudioSession sharedInstance];
        
        NSError *error = nil;
        if ([_audioEngine startAndReturnError:&error])
        {
            NSLog(@"error: %@", error);
        
        
        [_audioSession setActive:YES error:&error];
        [_audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [_audioSession activateWithOptions:AVAudioSessionActivationOptionNone completionHandler:^(BOOL activated, NSError * _Nullable error) {
            
        }];
    }
    }
    
    return self;
}

-(float)generateRandomNumberBetweenMin:(int)min Max:(int)max
{
    return ( (arc4random() % (max-min+1)) + min );
}

-(AVAudioPCMBuffer *)createAudioBufferWithLoopableSineWaveFrequency:(NSUInteger)frequency
{
    AVAudioFormat *mixerFormat = [_mixerNode outputFormatForBus:0];
    NSUInteger randomNum = [self generateRandomNumberBetweenMin:1 Max:4];
    double frameLength = mixerFormat.sampleRate / randomNum;
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerFormat frameCapacity:frameLength];
    pcmBuffer.frameLength = frameLength;
    
    float *leftChannel = pcmBuffer.floatChannelData[0];
    float *rightChannel = mixerFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;
    
    NSUInteger r = arc4random_uniform(2);
    double amplitude_step  = (1.0 / frameLength > 0.000100) ? (((double)arc4random() / 0x100000000) * (0.000100 - 0.000021) + 0.000021) : 1.0 / frameLength;
    double amplitude_value = 0.0;
    for (int i_sample = 0; i_sample < pcmBuffer.frameCapacity; i_sample++)
    {
        amplitude_value += amplitude_step;
        double amplitude = pow(((r == 1) ? ((amplitude_value < 1.0) ? (amplitude_value) : 1.0) : ((1.0 - amplitude_value > 0.0) ? 1.0 - (amplitude_value) : 0.0)), ((r == 1) ? randomNum : 1.0/randomNum));
        amplitude = ((amplitude < 0.000001) ? 0.000001 : amplitude);
        double value = sinf((frequency*i_sample*2*M_PI) / mixerFormat.sampleRate);
        if (leftChannel)  leftChannel[i_sample]  = value * amplitude;
        if (rightChannel) rightChannel[i_sample] = value * (1.0 - amplitude);
    }

    return pcmBuffer;
}


//- (void)start
//{
//    if (self.audioEngine.isRunning == NO)
//    {
//        NSError *error = nil;
//        [_audioEngine startAndReturnError:&error];
//        NSLog(@"error: %@", error);
//    }
//
//
//    if (self->_timer != nil) [self stop];
//    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//    dispatch_source_set_timer(self->_timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
//    dispatch_source_set_event_handler(self->_timer, ^{
//        if ([self->_playerOneNode isPlaying] || [self->_playerTwoNode isPlaying])
//        {
//            [self->_playerOneNode stop];
//            [self->_playerTwoNode stop];
//        }
//
//        if (self->_playerOneNode)
//        {
//            AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
//
//            [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//
//            }];
//
//            [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//
//            }];
//
//            [self->_playerOneNode play];
//        }
//    });
//    dispatch_resume(self.timer);
//}

- (void)start
 {
     if (self.audioEngine.isRunning == NO)
     {
         NSError *error = nil;
         [_audioEngine startAndReturnError:&error];
         NSLog(@"error: %@", error);
     }

     if (self->_timer != nil) [self stop];

     self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
     dispatch_source_set_timer(self->_timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
     dispatch_source_set_event_handler(self->_timer, ^{
         if (![self->_playerOneNode isPlaying] || ![self->_playerTwoNode isPlaying])
         {
             [self->_playerOneNode play];
             [self->_playerTwoNode play];
         }

         if (self->_playerOneNode && self->_playerTwoNode)
         {
             AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
             double frequencyOne = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
             [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                 
             }];
             
             float randomNum = (((double)arc4random() / 0x100000000) * (1.0 - 0.0) + 0.0); //((float)rand() / RAND_MAX) * 1;
             CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
             AVAudioTime *start_time_two = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];

             double frequencyTwo = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
             [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyTwo] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                 
             }];
          }
     });
     dispatch_resume(self.timer);
 }

//
// - (void)start
// {
//     if (self.audioEngine.isRunning == NO)
//     {
//         NSError *error = nil;
//         [_audioEngine startAndReturnError:&error];
//         NSLog(@"error: %@", error);
//     }
//
//     if (self->_timer != nil) [self stop];
//
//     self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//     dispatch_source_set_timer(self->_timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
//     dispatch_source_set_event_handler(self->_timer, ^{
//         if (![self->_playerOneNode isPlaying] || ![self->_playerTwoNode isPlaying])
//         {
//             [self->_playerOneNode play];
//             [self->_playerTwoNode play];
//         }
//
//         AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
//         if (self->_playerOneNode && self->_playerTwoNode)
//         {
//             [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//
//             }];
//
//             [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//
//             }];
//         }
//
//         float randomNum = ((float)rand() / RAND_MAX) * 1;
//         CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
//         AVAudioTime *start_time_two = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
//          if (self->_playerOneNode && self->_playerTwoNode)
//          {
//              [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//
//              }];
//
//              [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//
//              }];
//          }
//     });
//     dispatch_resume(self.timer);
// }

- (void)stop
{
    dispatch_source_cancel(self->_timer);
    self->_timer = nil;
    [_playerOneNode stop];
    [_playerTwoNode stop];
}

@end

