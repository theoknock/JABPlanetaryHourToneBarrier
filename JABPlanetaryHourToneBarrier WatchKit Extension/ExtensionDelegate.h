//
//  ExtensionDelegate.h
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <UserNotifications/UserNotifications.h>
#import <HealthKit/HealthKit.h>
#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSUInteger, HeartRateMonitorStatus) {
    HeartRateMonitorPermissionDenied,
    HeartRateMonitorPermissionGranted,
    HeartRateMonitorDataUnavailable,
    HeartRateMonitorDataAvailable
    
};

@protocol WatchConnectivityStatusInterfaceProtocol <NSObject>

- (void)updateStatusInterfaceForActivationState:(WCSessionActivationState)activationState reachability:(BOOL)reachable;
- (void)updatePeerDeviceStatusInterface:(NSDictionary *)receivedApplicationContext;
- (void)updateToneGeneratorStatus:(BOOL)playing;
- (void)updateHeartRateMonitorStatus:(HeartRateMonitorStatus)heartRateMonitorStatus;

@end

@interface ExtensionDelegate : NSObject <WKExtensionDelegate, WCSessionDelegate>

@property (nonatomic, weak) id<WatchConnectivityStatusInterfaceProtocol> watchConnectivityStatusInterfaceDelegate;
- (WCSession *)watchConnectivitySession;
@end
