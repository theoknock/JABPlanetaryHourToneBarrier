//
//  WatchToneBarrierInterfaceController.h
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 10/30/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <HealthKit/HealthKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HeartRateMonitorStatus) {
    HeartRateMonitorPermissionDenied,
    HeartRateMonitorPermissionGranted,
    HeartRateMonitorDataUnavailable,
    HeartRateMonitorDataAvailable
    
};

@interface WatchToneBarrierInterfaceController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *buttonImageGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *heartImage;

@end

NS_ASSUME_NONNULL_END
