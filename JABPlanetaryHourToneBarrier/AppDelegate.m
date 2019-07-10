//
//  AppDelegate.m
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "AppDelegate.h"
#import <BackgroundTasks/BackgroundTasks.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:@"com.blogspot.demonicactivity.bush.alan.james.JABPlanetaryHourToneBarrier.receiveApplicationContext"
                                                          usingQueue:nil launchHandler:^(__kindof BGTask * _Nonnull task) {
        [self handleAppRefresh:(BGAppRefreshTask *)task];
    }];
    
    return YES;
}

- (void)scheduleAppRefresh
{
    BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:@"com.blogspot.demonicactivity.bush.alan.james.JABPlanetaryHourToneBarrier.receiveApplicationContext"];
    [request setEarliestBeginDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
    
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

- (void)handleAppRefresh:(BGAppRefreshTask *)task
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
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self scheduleAppRefresh];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end
