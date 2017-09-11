//
//  OpenFileButton.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/5.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef NS_ENUM(NSInteger,MouseStat) {
    MouseStatExited,
    MouseStatEntered,
    MouseStatUp,
    MouseStatDown,
};

@interface MouseButton : NSButton
- (void)changePlayOrPauseImage:(BOOL)isPlaying;
- (void)setCurrntStat:(MouseStat)stat;
@end
