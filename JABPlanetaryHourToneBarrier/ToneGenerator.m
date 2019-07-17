//
//  ToneGenerator.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "ToneGenerator.h"

static const AVAudioFrameCount kSamplesPerBuffer = 1024;
static const float high_frequency = 4000.0f;
static const float low_frequency = 500.0f;

@interface ToneGenerator ()

@property (nonatomic, readonly) AVAudioMixerNode *mixerNode;
@property (nonatomic, readonly) AVAudioPlayerNode *playerOneNode;
@property (nonatomic, readonly) AVAudioPlayerNode *playerTwoNode;
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
    for (NSUInteger i_sample=0; i_sample < pcmBuffer.frameLength; i_sample++)
    {
        CGFloat value = sinf(theta);
        
        theta += increment;
        
        if (theta > 2.0f * M_PI) theta -= (2.0f * M_PI);
        
        if (leftChannel)  leftChannel[i_sample] = value * .5f;
        if (rightChannel) rightChannel[i_sample] = value * .5f;
    }
    
    return pcmBuffer;
}

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
        if ([self->_playerOneNode isPlaying] || [self->_playerTwoNode isPlaying])
        {
            [self->_playerOneNode stop];
            [self->_playerTwoNode stop];
        }

        if (self->_playerOneNode)
        {
            [self->_playerOneNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                
            }];
            
            [self->_playerOneNode play];
        }
        
        if (self->_playerTwoNode)
        {
            [self->_playerTwoNode scheduleBuffer:[self createAudioBufferWithLoopableSineWaveFrequency:(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)] atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                
            }];
            
            [self->_playerTwoNode play];
        }
    });
    dispatch_resume(self.timer);
}

-(void)stop
{
    dispatch_source_cancel(self->_timer);
    self->_timer = nil;
    [_playerOneNode stop];
    [_playerTwoNode stop];
}

@end


