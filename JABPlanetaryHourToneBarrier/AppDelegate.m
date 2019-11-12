//
//  AppDelegate.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "AppDelegate.h"
#import <BackgroundTasks/BackgroundTasks.h>
#import "ToneGenerator.h"

@interface AppDelegate ()
{
    dispatch_source_t timer;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:@"com.blogspot.demonicactivity.bush.alan.james.JABPlanetaryHourToneBarrier.receiveApplicationContext"
                                                          usingQueue:dispatch_get_main_queue() launchHandler:^(__kindof BGTask * _Nonnull task) {
        if (self->timer) self->timer = nil;
        self->timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self->timer, DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self->timer, ^{
            [self handleWatchConnectivityUpdate:(BGAppRefreshTask *)task];
        });
        dispatch_resume(self->timer);
    }];
    
    return YES;
}

- (void)scheduleAppRefresh
{
    BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:@"com.blogspot.demonicactivity.bush.alan.james.JABPlanetaryHourToneBarrier.receiveApplicationContext"];
    [request setEarliestBeginDate:[NSDate date]];
    
    __autoreleasing NSError *error;
    @try {
        NSLog(@"\n\nSubmitting task request: %@", request.description);
        [[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&error];
    } @catch (NSException *exception) {
        NSLog(@"\n\nCannot submit task request: %@", exception.description);
    } @finally {
        if (error)
        {
            NSLog(@"\n\nFailed to submit task request:\n%@\n%@", request.description, error.description);
        } else {
            NSLog(@"\n\nSubmitted task request %@", request.description);
        }
    }
}

- (void)handleWatchConnectivityUpdate:(BGAppRefreshTask *)task
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *task_desc = task.description;
    [task setExpirationHandler:^{
        NSLog(@"\n\nExpired task: %@", task_desc);
    }];
    [self.deviceStatusInterfaceDelegate updateDeviceStatus];
    [task setTaskCompletedWithSuccess:TRUE];
    NSLog(@"Completed task: %@", task.description);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    NSLog(@"%s", __PRETTY_FUNCTION__);
//    [self scheduleAppRefresh];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    NSLog(@"%s", __PRETTY_FUNCTION__);
//    [self scheduleAppRefresh];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    
    [[remoteCommandCenter togglePlayPauseCommand] addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![ToneGenerator.sharedGenerator.playerOneNode isPlaying]) {
                    [ToneGenerator.sharedGenerator start];
            } else if ([ToneGenerator.sharedGenerator.playerOneNode isPlaying]) {
                [ToneGenerator.sharedGenerator stop];
            }
        });
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.deviceStatusInterfaceDelegate updateDeviceStatus];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.deviceStatusInterfaceDelegate updateDeviceStatus];
}


@end
