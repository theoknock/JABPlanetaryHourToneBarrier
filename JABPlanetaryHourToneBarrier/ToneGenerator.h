//
//  ToneGenerator.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, StereoChannels) {
    StereoChannelR,
    StereoChannelL
};

@protocol ToneWaveRendererDelegate <NSObject>

- (void)drawFrequency:(double)frequency amplitude:(double)amplitude channel:(StereoChannels)channel;

@end

@interface ToneGenerator : NSObject

@property (nonatomic, readonly) AVAudioEngine * _Nonnull audioEngine;

+ (nonnull ToneGenerator *)sharedGenerator;

@property (nonatomic, weak) id<ToneWaveRendererDelegate> _Nullable toneWaveRendererDelegate;
@property (nonatomic, strong) dispatch_source_t _Nullable timer;

- (void)start;
- (void)stop;

@end
