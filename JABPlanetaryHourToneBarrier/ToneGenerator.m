//
//  ToneGenerator.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "ToneGenerator.h"

#include "easing.h"

static const AVAudioFrameCount kSamplesPerBuffer = 2048;
static const float high_frequency = 2048.0;
static const float low_frequency = 500.0f;

@interface ToneGenerator ()

@property (nonatomic, readonly) AVAudioMixerNode *mixerNode;
@property (nonatomic, readonly) AVAudioPCMBuffer* pcmBufferOne;
@property (nonatomic, readonly) AVAudioPCMBuffer* pcmBufferTwo;

@end

@implementation ToneGenerator

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

static ToneGenerator *sharedGenerator = NULL;
+ (nonnull ToneGenerator *)sharedGenerator
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
        //        semaphore = dispatch_semaphore_create(1);
        _audioEngine = [[AVAudioEngine alloc] init];
        
        _mixerNode = _audioEngine.mainMixerNode;
        
        _playerOneNode = [[AVAudioPlayerNode alloc] init];
        [_audioEngine attachNode:_playerOneNode];
        
        [_audioEngine connect:_playerOneNode to:_mixerNode format:[_playerOneNode outputFormatForBus:0]];
        
        _playerTwoNode = [[AVAudioPlayerNode alloc] init];
        [_audioEngine attachNode:_playerTwoNode];
        
        [_audioEngine connect:_playerTwoNode to:_mixerNode format:[_playerTwoNode outputFormatForBus:0]];
        
        NSError *error = nil;
        [_audioEngine startAndReturnError:&error];
        
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    return self;
}

- (float)generateRandomNumberBetweenMin:(int)min Max:(int)max
{
    return ( (arc4random() % (max-min+1)) + min );
}


float normalize(float unscaledNum, float minAllowed, float maxAllowed, float min, float max) {
    return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
}



//- (AVAudioPCMBuffer *)createAudioBufferWithLoopableSineWaveFrequency:(NSUInteger)frequency
//{
//    AVAudioFormat *mixerFormat = [_mixerNode outputFormatForBus:0];
//    NSUInteger randomNum = [self generateRandomNumberBetweenMin:1 Max:4];
//    double frameLength = mixerFormat.sampleRate / randomNum;
//    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerFormat frameCapacity:frameLength];
//    pcmBuffer.frameLength = frameLength;
//
//    float *leftChannel = pcmBuffer.floatChannelData[0];
//    float *rightChannel = mixerFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;
//
//    NSUInteger r = arc4random_uniform(2);
//    double amplitude_step  = (1.0 / frameLength > 0.000100) ? (((double)arc4random() / 0x100000000) * (0.000100 - 0.000021) + 0.000021) : 1.0 / frameLength;
//    double amplitude_value = 0.0;
//    for (int i_sample = 0; i_sample < pcmBuffer.frameCapacity; i_sample++)
//    {
//        amplitude_value += amplitude_step;
//        double amplitude = pow(((r == 1) ? ((amplitude_value < 1.0) ? (amplitude_value) : 1.0) : ((1.0 - amplitude_value > 0.0) ? 1.0 - (amplitude_value) : 0.0)), ((r == 1) ? randomNum : 1.0/randomNum));
//        amplitude = ((amplitude < 0.000001) ? 0.000001 : amplitude);
//        double value = sinf((frequency*i_sample*2*M_PI) / mixerFormat.sampleRate);
//        if (leftChannel)  leftChannel[i_sample]  = value * amplitude;
//        if (rightChannel) rightChannel[i_sample] = value * (1.0 - amplitude);
//    }
//
//    return pcmBuffer;
//}
//
typedef void (^PlayToneCompletionBlock)(void);
typedef void (^CreateAudioBufferCompletionBlock)(AVAudioPCMBuffer *buffer1, AVAudioPCMBuffer *buffer2, PlayToneCompletionBlock playToneCompletionBlock);

- (void)createAudioBufferWithCompletionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    static AVAudioPCMBuffer * (^createAudioBuffer)(NSUInteger);
    createAudioBuffer = ^AVAudioPCMBuffer *(NSUInteger bufferIndex)
    {
        double leftFrequency  = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
        double rightFrequency =(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
      
        AVAudioFormat *mixerFormat = [self->_mixerNode outputFormatForBus:0];
        double frameLength = mixerFormat.sampleRate * 2.0;
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerFormat frameCapacity:frameLength];
        pcmBuffer.frameLength = frameLength;
        
        float *leftChannel = pcmBuffer.floatChannelData[0];
        float *rightChannel = mixerFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;
        
        for (int index = 0; index < (int)frameLength; index++)
        {
            double amplitude = 0;
            double normalized_index = LinearInterpolation(index, frameLength);
            if ((bufferIndex == 2) && (index <= 0.5))
            {
                amplitude = 0;
            } else {
                amplitude = NormalizedSineEaseInOut(normalized_index, 4);
            }
            //        NSLog(@"amplitudeLeft %f", amplitude);
            //        NSLog(@"amplitudeLeft %f", ((double)(i_sample / frameLength) < 0.4 && ((double)(i_sample / frameLength) < 0.5)) ? ((double)(i_sample / frameLength)) * 2.0 : @"");
            double leftValue = sinf((leftFrequency*index*2*M_PI) / frameLength);
            double rightValue = sinf((rightFrequency*index*2*M_PI) / frameLength);
            if (leftChannel)  leftChannel[index]  = leftValue * amplitude;
            if (rightChannel)  rightChannel[index]  = rightValue * (1.0 - amplitude);
            //        if (rightChannel) rightChannel[(pcmBuffer.frameCapacity - 1) - i_sample] = value * amplitude;
        }
        return pcmBuffer;
    };
    
    static void (^block)(void);
    block = ^void(void)
    {
        createAudioBufferCompletionBlock(createAudioBuffer(1), createAudioBuffer(2), ^{
            if ([self->_playerOneNode isPlaying] || [self->_playerTwoNode isPlaying])
            {
                block();
                NSLog(@"Calling block...");
            }
        });
    };
    
    createAudioBufferCompletionBlock(createAudioBuffer(1), createAudioBuffer(2), ^{
        if ([self->_playerOneNode isPlaying] || [self->_playerTwoNode isPlaying])
        {
            block();
            NSLog(@"Calling block...");
        }
    });
}

- (void)start
{
    if (self.audioEngine.isRunning == NO)
    {
        NSError *error = nil;
        [_audioEngine startAndReturnError:&error];
        NSLog(@"error: %@", error);
    }
    
    if (self->_playerOneNode)
    {
        [self createAudioBufferWithCompletionBlock:^(AVAudioPCMBuffer *buffer1, AVAudioPCMBuffer *buffer2, PlayToneCompletionBlock playToneCompletionBlock) {
            [self->_playerOneNode scheduleBuffer:buffer1 atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
//                if (callbackType == AVAudioPlayerNodeCompletionDataPlayedBack)
//                    playToneCompletionBlock();
                NSLog(@"Calling playToneCompletionBlock 1...");
            }];
            [self->_playerTwoNode scheduleBuffer:buffer2 atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
                            if (callbackType == AVAudioPlayerNodeCompletionDataPlayedBack)
                                playToneCompletionBlock();
                            NSLog(@"Calling playToneCompletionBlock 2...");
                        }];
        }];
    }
    //
    //    if (self->_playerTwoNode)
    //    {
    //        [self createAudioBufferWithCompletionBlock:^(AVAudioPCMBuffer *buffer, PlayToneCompletionBlock playToneCompletionBlock) {
    //            [self->_playerTwoNode scheduleBuffer:buffer atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
    //                if (callbackType == AVAudioPlayerNodeCompletionDataPlayedBack)
    //                    playToneCompletionBlock();
    //                NSLog(@"Calling playToneCompletionBlock 2...");
    //            }];
    //        }];
    //    }
    
    if (![self->_playerOneNode isPlaying] || ![self->_playerTwoNode isPlaying])
    {
        [self->_playerOneNode play];
        [self->_playerTwoNode play];
    }
}

/*
 BARRIER ONE
 */

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

/*
 BARRIER TWO
 */

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
//         if (self->_playerOneNode && self->_playerTwoNode)
//         {
//             AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
//             double frequencyOne = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//             [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
////                 [self.toneWaveRendererDelegate drawFrequency:frequencyOne amplitude:1.0 channel:StereoChannelR];
//             }];
//
//             float randomNum = (((double)arc4random() / 0x100000000) * (1.0 - 0.0) + 0.0); //((float)rand() / RAND_MAX) * 1;
//             CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
//             AVAudioTime *start_time_two = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
////
//             double frequencyTwo = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//             [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyTwo] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
////                 [self.toneWaveRendererDelegate drawFrequency:frequencyTwo amplitude:1.0/2.0 channel:StereoChannelL];
//             }];
////         }
////
////
////          if (self->_playerOneNode && self->_playerTwoNode)
////          {
////              float randomNum = ((float)rand() / RAND_MAX) * 1;
////              CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
////              AVAudioTime *start_time_three = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
////              double frequencyOne = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
////              [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_three options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//////                  [self.toneWaveRendererDelegate drawFrequency:frequencyOne amplitude:1.0 channel:StereoChannelR];
////              }];
////
////              randomNum = ((float)rand() / RAND_MAX) * 1;
////              current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
////              AVAudioTime *start_time_four = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
////
////              double frequencyTwo = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
////              [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyTwo] atTime:start_time_four options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//////                  [self.toneWaveRendererDelegate drawFrequency:frequencyTwo amplitude:1.0/3.0 channel:StereoChannelL];
////              }];
//          }
//     });
//     dispatch_resume(self.timer);
// }

/*
 BARRIER THREE
 */

//- (void)start
//{
//    if (self.audioEngine.isRunning == NO)
//    {
//        NSError *error = nil;
//        [_audioEngine startAndReturnError:&error];
//        NSLog(@"error: %@", error);
//    }
//
//    if (self->_timer != nil) [self stop];
//
//    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//    dispatch_source_set_timer(self->_timer, DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
//    dispatch_source_set_event_handler(self->_timer, ^{
//        if (![self->_playerOneNode isPlaying] || ![self->_playerTwoNode isPlaying])
//        {
//            [self->_playerOneNode play];
//            [self->_playerTwoNode play];
//        }
//
//        NSUInteger r = arc4random_uniform(2);
//        switch (r) {
//            case 1: {
//                CMTime ctime = CMClockGetTime(CMClockGetHostTimeClock());
//                uint64_t htime = CMClockConvertHostTimeToSystemUnits(ctime);
//                if (self->_playerOneNode && self->_playerTwoNode)
//                {
//                    double freq = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:htime]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:htime]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    freq = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    float randomNum = ((float)rand() / RAND_MAX) * 1;
//                    [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMTimeAdd(ctime, CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC)))]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMTimeAdd(ctime, CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC)))]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    freq = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    randomNum += ((float)rand() / RAND_MAX) * 1;
//                    [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMTimeAdd(ctime, CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC)))]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMTimeAdd(ctime, CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC)))]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    freq = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    randomNum += ((float)rand() / RAND_MAX) * 1;
//                    [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMTimeAdd(ctime, CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC)))]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//
//                    [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:freq]
//                                                  atTime:[[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMTimeAdd(ctime, CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC)))]
//                                                 options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    }];
//                 }
//                break;
//            }
//
//            default: {
//                AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
//                if (self->_playerOneNode && self->_playerTwoNode)
//                {
//                    double frequencyOne = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    double frequencyTwo = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    //                         [self.toneWaveRendererDelegate drawFrequency:frequencyOne amplitude:1.0 channel:StereoChannelR];
//                    }];
//
//
//                    [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyTwo] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    //                         [self.toneWaveRendererDelegate drawFrequency:frequencyTwo amplitude:1.0 channel:StereoChannelL];
//                    }];
//                }
//
//                float randomNum = ((float)rand() / RAND_MAX) * 1;
//                CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
//                AVAudioTime *start_time_two = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
//                if (self->_playerOneNode && self->_playerTwoNode)
//                {
//                    double frequencyOne = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    //                          [self.toneWaveRendererDelegate drawFrequency:frequencyOne amplitude:1.0 channel:StereoChannelR];
//                    }];
//
//                    double frequencyTwo = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//                    [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyTwo] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//                    //                          [self.toneWaveRendererDelegate drawFrequency:frequencyTwo amplitude:1.0 channel:StereoChannelL];
//                    }];
//                }
//                }
//                break;
//        }
//
//
//    });
//    dispatch_resume(self.timer);
//}

//
//typedef NS_OPTIONS(NSUInteger, Texture) {
//    Monophonic = 1 << 0,
//    Heterophonic = 1 << 1
//};
//
//// Phonaesthesia: the study of aesthetic properties of sounds
//typedef NS_OPTIONS(NSUInteger, Phonaesthetic) {
//    Cacophonic = 1 << 0,
//    Euphonic = 1 << 1
//};
//
//typedef NS_ENUM(NSUInteger, Rhythm) {
//    Monody,
//    Heterodony
//};
//
//
//static void (^generateTone)(AVAudioPlayerNode *) = ^(AVAudioPlayerNode *playerNode) {
//    // Loop the number of stereoChannels
//    AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
//        double frequencyOne = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
//        [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
//            if ([self->_playerOneNode isPlaying] && [self->_playerTwoNode isPlaying])
//                generateTones(stereoChannels);
//        }];
//};
//
//- (void)play:(StereoChannels)stereoChannels
//{
//    if (self.audioEngine.isRunning == NO)
//    {
//        NSError *error = nil;
//        [_audioEngine startAndReturnError:&error];
//        NSLog(@"error: %@", error);
//    }
//
//    if ((stereoChannels & StereoChannelRight) && self->_playerOneNode)
//    {
//        if (![self->_playerOneNode isPlaying])
//            [self->_playerOneNode play];
//
//        generateTones(self->_playerOneNode);
//
//    }
//
//    if ((stereoChannels & StereoChannelLeft) && self->_playerTwoNode)
//    {
//        if (![self->_playerTwoNode isPlaying])
//            [self->_playerTwoNode play];
//
//        generateTones(self->_playerTwoNode);
//    }
//}

- (void)stop
{
    //    dispatch_source_cancel(self->_timer);
    //    self->_timer = nil;
    [_playerOneNode stop];
    [_playerTwoNode stop];
}

//- (void)alarm
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
//         if (![self->_playerOneNode isPlaying] || ![self->_playerTwoNode isPlaying])
//         {
//             [self->_playerOneNode play];
//             [self->_playerTwoNode play];
//         }
//
//         if (self->_playerOneNode && self->_playerTwoNode)
//         {
//             AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
//             double frequencyOne = (high_frequency + low_frequency) / 2.0;
//             [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyOne] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
////                 [self.toneWaveRendererDelegate drawFrequency:frequencyOne amplitude:1.0 channel:StereoChannelR];
//             }];
//
//             double frequencyTwo = high_frequency;
//             [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:frequencyTwo] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
////                 [self.toneWaveRendererDelegate drawFrequency:frequencyTwo amplitude:1.0/2.0 channel:StereoChannelL];
//             }];
//          }
// }

@end



