//
//  ExtensionDelegate.m
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "ExtensionDelegate.h"
#import <JABPlanetaryHourWatchFramework/JABPlanetaryHourWatchFramework.h>
#import "WatchToneGenerator.h"

@interface ExtensionDelegate ()
{
    WCSession *watchConnectivitySession;
}

@end

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    [self activateWatchConnectivitySession];
    [self requestPeerDeviceStatus]; // EXTRANEOUS?
    NSIndexSet *daysIndices  = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, 1)];
       NSIndexSet *dataIndices  = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, 2)];
       NSIndexSet *hoursIndices = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(20, 1)];
       
       [[PlanetaryHourDataSource data] solarCyclesForDays:daysIndices
                                        planetaryHourData:dataIndices
                                           planetaryHours:hoursIndices
              planetaryHourDataSourceStartCompletionBlock:^{
           NSLog(@"%s", __PRETTY_FUNCTION__);
       }
                                solarCycleCompletionBlock:^(NSDictionary<NSNumber *,NSDate *> * _Nonnull solarCycle) {
           NSLog(@"%s", __PRETTY_FUNCTION__);
       }
                             planetaryHourCompletionBlock:^(NSDictionary<NSNumber *,id> * _Nonnull planetaryHour) {
           NSLog(@"%s", __PRETTY_FUNCTION__);
           
           NSTimeInterval startDelay = [[planetaryHour objectForKey:@(StartDate)] timeIntervalSinceDate:[NSDate date]];
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(startDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [WatchToneGenerator.sharedGenerator start];
           });
           NSTimeInterval stopDelay = [[planetaryHour objectForKey:@(EndDate)] timeIntervalSinceDate:[NSDate date]];
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(stopDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [WatchToneGenerator.sharedGenerator stop];
           });
           NSLog(@"\nStart:\t%f\nEnd:\t%f", startDelay, stopDelay);
       }
                            planetaryHoursCompletionBlock:nil
                planetaryHoursCalculationsCompletionBlock:nil
                   planetaryHourDataSourceCompletionBlock:nil];
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self activateWatchConnectivitySession];
    [self requestPeerDeviceStatus]; // EXTRANEOUS?
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
    [[WKExtension sharedExtension] scheduleBackgroundRefreshWithPreferredDate:[[NSDate date] dateByAddingTimeInterval:3.0] userInfo:@{@"DeviceStatus" : @"Send"} scheduledCompletion:^(NSError * _Nullable error) {
                    NSLog(@"Background refresh task error:\t%@", error.description);
                    [self requestPeerDeviceStatus];
                }];
}

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
    // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
    for (WKRefreshBackgroundTask * task in backgroundTasks) {
        // Check the Class of each task to decide how to process it
        if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
            
            [[WKExtension sharedExtension] scheduleBackgroundRefreshWithPreferredDate:[[NSDate date] dateByAddingTimeInterval:3.0]userInfo:@{@"DeviceStatus" : @"Send"} scheduledCompletion:^(NSError * _Nullable error) {
                            NSLog(@"Background refresh task error:\t%@", error.description);
                            [self requestPeerDeviceStatus];
                        }];
            
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {
            // Snapshot tasks have a unique completion call, make sure to set your expiration date
            WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
            [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
        } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
            
            [[WKExtension sharedExtension] scheduleBackgroundRefreshWithPreferredDate:[[NSDate date] dateByAddingTimeInterval:3.0]userInfo:@{@"DeviceStatus" : @"Send"} scheduledCompletion:^(NSError * _Nullable error) {
                NSLog(@"Background refresh task error:\t%@", error.description);
                [self requestPeerDeviceStatus];
            }];

            [backgroundTask setTaskCompletedWithSnapshot:YES];
            
        } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKRelevantShortcutRefreshBackgroundTask class]]) {
            // Be sure to complete the relevant-shortcut task once you’re done.
            WKRelevantShortcutRefreshBackgroundTask *relevantShortcutTask = (WKRelevantShortcutRefreshBackgroundTask*)task;
            [relevantShortcutTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKIntentDidRunRefreshBackgroundTask class]]) {
            // Be sure to complete the intent-did-run task once you’re done.
            WKIntentDidRunRefreshBackgroundTask *intentDidRunTask = (WKIntentDidRunRefreshBackgroundTask*)task;
            [intentDidRunTask setTaskCompletedWithSnapshot:NO];
        } else {
            // make sure to complete unhandled task types
            [task setTaskCompletedWithSnapshot:NO];
        }
    }
}

- (WCSession *)watchConnectivitySession
{
    return watchConnectivitySession;
}

- (void)activateWatchConnectivitySession
{
    [self.watchConnectivityStatusInterfaceDelegate updateStatusInterfaceForActivationState:watchConnectivitySession.activationState reachability:watchConnectivitySession.isReachable];
    watchConnectivitySession = [WCSession defaultSession];
    [watchConnectivitySession setDelegate:(id<WCSessionDelegate> _Nullable)self];
    [watchConnectivitySession activateSession];
}

- (void)session:(nonnull WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error
{
    [self.watchConnectivityStatusInterfaceDelegate updateStatusInterfaceForActivationState:activationState reachability:session.isReachable];
    if (activationState != WCSessionActivationStateActivated) [self activateWatchConnectivitySession];
    else
        if (activationState == WCSessionActivationStateActivated) [self requestPeerDeviceStatus];
}

- (void)sessionReachabilityDidChange:(WCSession *)session
{
    [self.watchConnectivityStatusInterfaceDelegate updateStatusInterfaceForActivationState:session.activationState reachability:session.isReachable];
    if (session.isReachable) [self requestPeerDeviceStatus];
    else [self activateWatchConnectivitySession];
}

- (void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext
{
    [self.watchConnectivityStatusInterfaceDelegate updateStatusInterfaceForActivationState:session.activationState reachability:session.isReachable];
    [self.watchConnectivityStatusInterfaceDelegate updatePeerDeviceStatusInterface:applicationContext];
}

- (void)requestPeerDeviceStatus
{
    [self.watchConnectivitySession updateApplicationContext:@{@"DeviceStatus" : @"Send"} error:nil];
}


@end


