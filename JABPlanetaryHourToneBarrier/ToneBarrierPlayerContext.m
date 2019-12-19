//
//  ToneBarrierPlayerContext.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 12/17/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ToneBarrierPlayerContext.h"

@implementation ToneBarrierPlayerContext

- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock;
{
    [_player createAudioBufferWithFormat:audioFormat completionBlock:createAudioBufferCompletionBlock];
}

@end
