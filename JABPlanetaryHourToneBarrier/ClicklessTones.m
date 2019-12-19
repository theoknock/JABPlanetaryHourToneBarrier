//
//  ClicklessTones.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ClicklessTones.h"
#include "easing.h"


static const float high_frequency = 6000.0;
static const float low_frequency  = 1000.0;


@implementation ClicklessTones

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    NSLog(@"ClicklessTones");
    static AVAudioPCMBuffer * (^createAudioBuffer)(NSUInteger);
    createAudioBuffer = ^AVAudioPCMBuffer *(NSUInteger bufferIndex)
    {
//        AVAudioFormat *audioFormat = [self->_mixerNode outputFormatForBus:0];
        AVAudioFrameCount frameCount = audioFormat.sampleRate * 2.0;
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
        pcmBuffer.frameLength = frameCount;
        float *leftChannel = pcmBuffer.floatChannelData[0];
        float *rightChannel = audioFormat.channelCount == 2 ? pcmBuffer.floatChannelData[1] : nil;
        
        double leftFrequency[2]  = {(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency), (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)};
        double rightFrequency[2] = {(((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency), (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)};
        int amplitude_frequency = arc4random_uniform(24) + 8;
        for (int index = 0; index < frameCount; index++)
        {
            double normalized_index   = LinearInterpolation(index, frameCount);
            //            double scaled_index       = normalized_index;
            //            double leftFrequency_avg  = ((leftFrequency[0]  * scaled_index) + (leftFrequency[1]  * (1.0 - scaled_index)));
            //            double rightFrequency_avg = ((rightFrequency[0] * scaled_index) + (rightFrequency[1] * (1.0 - scaled_index)));
            
            double leftFrequency_avg  = leftFrequency[0];
            double rightFrequency_avg = rightFrequency[0];
            
            if (leftChannel)  leftChannel[index]   = NormalizedSineEaseInOut(normalized_index, leftFrequency_avg,  1) * NormalizedSineEaseInOut(normalized_index, amplitude_frequency, 1);
            if (rightChannel) rightChannel[index]  = NormalizedSineEaseInOut(normalized_index, rightFrequency_avg, 1) * NormalizedSineEaseInOut(normalized_index, amplitude_frequency, 1);
        }
        return pcmBuffer;
    };
    
    static void (^block)(void);
    block = ^void(void)
    {
        createAudioBufferCompletionBlock(createAudioBuffer(1), createAudioBuffer(2), ^{
            block();
        });
    };
    block();
}

@end
