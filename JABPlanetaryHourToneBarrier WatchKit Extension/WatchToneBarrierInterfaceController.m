//
//  WatchToneBarrierInterfaceController.m
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 10/30/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import "WatchToneBarrierInterfaceController.h"
#import "WatchToneGenerator.h"

@interface WatchToneBarrierInterfaceController ()
{
    dispatch_source_t timer;
}

@end

@implementation WatchToneBarrierInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)toggleToneGenerator {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([WatchToneGenerator.sharedGenerator timer] == nil) {
            [WatchToneGenerator.sharedGenerator start];
            [self.buttonImageGroup setBackgroundImage:[UIImage systemImageNamed:@"stop"]];
            
//            timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//            dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC, 0.0 * NSEC_PER_SEC);
//            dispatch_source_set_event_handler(timer, ^{
//                __block HeartRateMonitorStatus heartRateMonitorStatus = HeartRateMonitorDataUnavailable;
//                if ([HKHealthStore isHealthDataAvailable]) {
//                    NSLog(@"Health data is available");
//                    heartRateMonitorStatus = HeartRateMonitorDataAvailable;
//                    HKHealthStore *healthStore = [HKHealthStore new];
//                    NSSet *objectTypes = [NSSet setWithArray:@[[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]]];
//                    [healthStore requestAuthorizationToShareTypes:objectTypes readTypes:objectTypes completion:^(BOOL success, NSError * _Nullable error) {
//                        if (!success) {
//                            NSLog(@"Access to health data denied: %@", error.description);
//                            heartRateMonitorStatus = HeartRateMonitorPermissionDenied;
//                        } else {
//                            NSLog(@"Access to health data granted");
//                            heartRateMonitorStatus = HeartRateMonitorPermissionGranted;
//                            HKHeartbeatSeriesBuilder *heartRateSeriesBuilder = [[HKHeartbeatSeriesBuilder alloc] initWithHealthStore:healthStore device:[HKDevice localDevice] startDate:[NSDate date]];
//                            [heartRateSeriesBuilder addHeartbeatWithTimeIntervalSinceSeriesStartDate:[[NSDate date] timeIntervalSinceDate:[[NSDate date] dateByAddingTimeInterval:-10000]] precededByGap:FALSE completion:^(BOOL success, NSError * _Nullable error) {
//                                if (success)
//                                    NSLog(@"Built heart rate series.");
//                                else
//                                    NSLog(@"Error building heart rate series:\t%@", error.description);
//                            }];
////                            [heartRateSeriesBuilder finishSeriesWithCompletion:^(HKHeartbeatSeriesSample * _Nullable heartbeatSeries, NSError * _Nullable error) {
////                                NSLog(@"Finished building series with count: %lu\nError: %@", (unsigned long)[heartbeatSeries count], error.description);
////                            }];
//                        }
//                    }];
//                } else {
//                    NSLog(@"Health data unavailable");
//                }
//                [self updateHeartRateMonitorStatus:heartRateMonitorStatus];
//            });
//            dispatch_resume(timer);
        } else if ([WatchToneGenerator.sharedGenerator timer] != nil) {
            [WatchToneGenerator.sharedGenerator stop];
            [self.buttonImageGroup setBackgroundImage:[UIImage systemImageNamed:@"play"]];
//            dispatch_source_cancel(timer);
//            timer = nil;
        }
    });
}

- (void)updateHeartRateMonitorStatus:(HeartRateMonitorStatus)heartRateMonitorStatus
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (heartRateMonitorStatus) {
            case HeartRateMonitorPermissionDenied:
            {
                [self.heartImage setImage:[UIImage systemImageNamed:@"heart.fill"]];
                [self.heartImage setTintColor:[UIColor darkGrayColor]];
                break;
            }

            case HeartRateMonitorPermissionGranted:
            {
                [self.heartImage setImage:[UIImage systemImageNamed:@"heart.fill"]];
                [self.heartImage setTintColor:[UIColor redColor]];
                break;
            }

            case HeartRateMonitorDataUnavailable:
            {
                [self.heartImage setImage:[UIImage systemImageNamed:@"heart.slash"]];
                [self.heartImage setTintColor:[UIColor darkGrayColor]];
                break;
            }

            case HeartRateMonitorDataAvailable:
            {
                [self.heartImage setImage:[UIImage systemImageNamed:@"heart.fill"]];
                [self.heartImage setTintColor:[UIColor greenColor]];
                break;
            }

            default:
            {
                [self.heartImage setImage:[UIImage systemImageNamed:@"heart.slash"]];
                [self.heartImage setTintColor:[UIColor darkGrayColor]];
                break;
            }
        }
    });
}

@end



