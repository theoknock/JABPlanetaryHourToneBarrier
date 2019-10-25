//
//  WatchToneGenerator.h
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/31/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WatchToneGenerator : NSObject

@property (nonatomic, readonly) AVAudioEngine *audioEngine;

+ (nonnull WatchToneGenerator *)sharedGenerator;

@property (nonatomic, strong) dispatch_source_t timer;

@property (nonatomic, readonly) AVAudioPlayerNode * _Nullable playerOneNode;
@property (nonatomic, readonly) AVAudioPlayerNode * _Nullable playerTwoNode;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
