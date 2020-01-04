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

@interface ClicklessTones ()
{
    double frequency[2];
    NSInteger alternate_channel_flag;
}

@end


@implementation ClicklessTones

typedef NS_ENUM(NSUInteger, Fade) {
    FadeIn,
    FadeOut
};

double (^fade)(Fade, double, int) = ^double(Fade fadeType, double x, int frequency)
{
    double amplitude = ((fadeType == FadeIn) ? (1.0 - x) : x); //NormalizedSineEaseInOut(x, frequency, 1);// * ((fadeType == FadeIn) ? (1.0 - x) : x);
    
    return amplitude;
};

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    
    self->frequency[0] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
    self->frequency[1] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency)
    ;
    static AVAudioPCMBuffer * (^createAudioBuffer)(Fade);
    createAudioBuffer = ^AVAudioPCMBuffer *(Fade leading_fade)
    {
//        AVAudioFormat *audioFormat = [self->_mixerNode outputFormatForBus:0];
        AVAudioFrameCount frameCount = audioFormat.sampleRate * 2.0;
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frameCount];
        pcmBuffer.frameLength = frameCount;
        float *left_channel  = pcmBuffer.floatChannelData[0];
        float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : nil;
        
        int amplitude_frequency = arc4random_uniform(24) + 8;
        for (int index = 0; index < frameCount; index++)
        {
            double normalized_index   = LinearInterpolation(index, frameCount);
            
            if (left_channel)  left_channel[index]  = NormalizedSineEaseInOut(normalized_index, self->frequency[0], 1) * fade(leading_fade, normalized_index, amplitude_frequency);
            if (right_channel) right_channel[index] = NormalizedSineEaseInOut(normalized_index, self->frequency[1], 1) * fade((leading_fade == FadeIn) ? FadeOut : FadeIn, normalized_index, amplitude_frequency);
        }
        return pcmBuffer;
    };
    
    static void (^block)(void);
    block = ^void(void)
    {
        NSLog(@"alternate_channel_flag == %ld", (long)self->alternate_channel_flag);
        self->alternate_channel_flag = (self->alternate_channel_flag == 1) ? 0 : (self->alternate_channel_flag + 1);
        self->frequency[0] = self->frequency[1];
        self->frequency[1] = (((double)arc4random() / 0x100000000) * (high_frequency - low_frequency) + low_frequency);
        createAudioBufferCompletionBlock(createAudioBuffer((Fade)self->alternate_channel_flag), createAudioBuffer((Fade)self->alternate_channel_flag), ^{
            block();
        });
    };
    block();
}

@end
