//
//  WatchToneGenerator.m
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/31/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "WatchToneGenerator.h"


static const AVAudioFrameCount kSamplesPerBuffer = 1024;
static const float high_frequency = 4000.0f;
static const float low_frequency = 500.0f;

@interface WatchToneGenerator ()

@property (nonatomic, readonly) AVAudioMixerNode *mixerNode;
@property (nonatomic, readonly) AVAudioPlayerNode *playerOneNode;
@property (nonatomic, readonly) AVAudioPlayerNode *playerTwoNode;
@property (nonatomic, readonly) AVAudioPCMBuffer* pcmBufferOne;
@property (nonatomic, readonly) AVAudioPCMBuffer* pcmBufferTwo;

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
        
        NSError *error = nil;
        [_audioEngine startAndReturnError:&error];
        NSLog(@"error: %@", error);
        
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    return self;
}

-(AVAudioPCMBuffer*)createAudioBufferWithLoopableSineWaveFrequency:(NSUInteger)frequency
{
    AVAudioFormat *mixerFormat = [_mixerNode outputFormatForBus:0];
    
    double sampleRate = mixerFormat.sampleRate;
    double frameLength = kSamplesPerBuffer;
    
    // BM: Find the greatest common divisor so that we can determine the number of full cycles
    // BM: and size of buffer needed to make a loop of a sine wav at this frequency for this
    // BM: sampleRate.  Otherwise we hear pops and clicks in our loops.
    NSUInteger gcd = [self greatestCommonDivisor:frequency secondValue:mixerFormat.sampleRate];
    if (gcd != 0)
    {
        // NSUInteger numberOfCycles = frequency / gcd;
        frameLength = mixerFormat.sampleRate / gcd;
    }
    
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerFormat frameCapacity:frameLength];
    pcmBuffer.frameLength = frameLength;
    
    float *leftChannel = pcmBuffer.floatChannelData[0];
    float *rightChannel = mixerFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;
    
    double increment = 2.0f * M_PI * frequency/sampleRate;
    double theta = 0.0f;
    NSUInteger r = arc4random_uniform(2);
    double amplitude_step  = 1.0 / pcmBuffer.frameLength;
    double amplitude_value = 0.0;
    float randomNum = ((float)rand() / RAND_MAX) * 4;
    if (randomNum < 1.0) randomNum = 1.0;
    for (NSUInteger i_sample=0; i_sample < pcmBuffer.frameLength; i_sample++)
    {
        CGFloat value = sinf(theta);
        
        theta += increment;
        
        if (theta > 2.0f * M_PI) theta -= (2.0f * M_PI);
        
        amplitude_value += amplitude_step;
        
        // ...alternating between channels...alternative between cycles...alternating between tones...
        if (leftChannel)  leftChannel[i_sample]  = value * pow(((r == 1) ? ((amplitude_value < 1.0) ? amplitude_value : 1.0) : ((1.0 - amplitude_value > 0.0) ? 1.0 - amplitude_value : 0.0)), ((r == 1) ? randomNum : 1.0/randomNum));
        if (rightChannel) rightChannel[i_sample] = value * pow(((r == 1) ? ((1.0 - amplitude_value > 0.0) ? 1.0 - amplitude_value : 0.0) : ((amplitude_value < 1.0) ? amplitude_value : 1.0)), ((r == 1) ? randomNum : 1.0/randomNum));
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

         AVAudioTime *start_time_one = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(CMClockGetTime(CMClockGetHostTimeClock()))];
         if (self->_playerOneNode && self->_playerTwoNode)
         {
             [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                 
             }];
             
             [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_one options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                 
             }];
         }
         
         float randomNum = ((float)rand() / RAND_MAX) * 1;
         CMTime current_cmtime = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()), CMTimeMakeWithSeconds(randomNum, NSEC_PER_SEC));
         AVAudioTime *start_time_two = [[AVAudioTime alloc] initWithHostTime:CMClockConvertHostTimeToSystemUnits(current_cmtime)];
          if (self->_playerOneNode && self->_playerTwoNode)
          {
              [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                  
              }];
              
              [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:start_time_two options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                  
              }];
          }
     });
     dispatch_resume(self.timer);
 }

- (void)stop
{
    dispatch_source_cancel(self->_timer);
    self->_timer = nil;
    [_playerOneNode stop];
    [_playerTwoNode stop];
}

@end
