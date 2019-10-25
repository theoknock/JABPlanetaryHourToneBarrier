//
//  SecondaryInterfaceController.h
//  
//
//  Created by Xcode Developer on 8/4/19.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SecondaryInterfaceController : WKInterfaceController

@property (weak, nonatomic) IBOutlet WKInterfaceButton *playButton;
@property (weak, nonatomic) IBOutlet WKInterfaceVolumeControl *volume;

@end

NS_ASSUME_NONNULL_END
