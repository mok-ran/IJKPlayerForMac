//
//  PlayerTitleBar.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/7.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlayerTitleBar : NSViewController
@property (copy)void(^closeWindowBlock)();
@property (copy)void(^minWindowBlock)();
@property (copy)void(^zoomWindowBlock)();
- (void)showBar;
- (void)hideBar;
@end
