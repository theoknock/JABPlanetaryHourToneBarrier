//
//  ToneGenerator.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface ToneGenerator : NSObject

@property (nonatomic, readonly) AVAudioEngine *audioEngine;

+ (nonnull ToneGenerator *)sharedGenerator;

@property (nonatomic, strong) dispatch_source_t timer;

- (void)start;
- (void)stop;

@end
