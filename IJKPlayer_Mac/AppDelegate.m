//
//  AppDelegate.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/6/2.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "AppDelegate.h"
#import "EventSendManager.h"
@interface AppDelegate ()
@property (nonatomic,weak)EventSendManager *menuManager;



@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.menuManager = [EventSendManager shareManager];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
- (IBAction)openFileClick:(NSMenuItem *)sender {
    if(self.menuManager.openFileBlock){
        self.menuManager.openFileBlock(sender);
    }
}
- (IBAction)openNetworkClick:(NSMenuItem *)sender {
    if(self.menuManager.openNetworkBlock){
        self.menuManager.openNetworkBlock(sender);
    }
}


@end
