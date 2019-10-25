//
//  AppDelegate.h
//  JABPlanetaryHourToneBarrier
//
//  Created by Xcode Developer on 7/8/19.
//  Copyright © 2019 The Life of a Demoniac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol DeviceStatusInterfaceDelegate <NSObject>

- (void)updateDeviceStatus;

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) id<DeviceStatusInterfaceDelegate> deviceStatusInterfaceDelegate;

@end

