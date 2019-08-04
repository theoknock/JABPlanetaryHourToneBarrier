//
//  SecondaryInterfaceController.m
//
//
//  Created by Xcode Developer on 8/4/19.
//

#import "SecondaryInterfaceController.h"
#import "WatchToneGenerator.h"

@interface SecondaryInterfaceController ()

@end

@implementation SecondaryInterfaceController

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
            [self.playButton setBackgroundImage:[UIImage systemImageNamed:@"stop.fill"]];
        } else if ([WatchToneGenerator.sharedGenerator timer] != nil) {
            [WatchToneGenerator.sharedGenerator stop];
            [self.playButton setBackgroundImage:[UIImage systemImageNamed:@"play.fill"]];
        }
    });
}

@end




