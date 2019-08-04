//
//  InterfaceController.h
//  JABPlanetaryHourToneBarrier WatchKit Extension
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceImage *activationImage;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *reachabilityImage;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *thermalStateImage;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *batteryStateImage;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playButton;
@property (weak, nonatomic) IBOutlet WKInterfaceImage *batteryLevelImage;
@property (weak, nonatomic) IBOutlet WKInterfaceVolumeControl *volume;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *playOnWatchButton;

@end
