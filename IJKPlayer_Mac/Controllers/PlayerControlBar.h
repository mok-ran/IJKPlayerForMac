//
//  PlayerControlBar.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/6.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IJKFFMoviePlayerController;
@interface PlayerControlBar : NSViewController
@property (copy)void(^playOrPauseBlock)();
@property (copy)void(^stopBlock)();
@property (copy)void(^progressChangedBlock)(CGFloat progress);
@property (copy)void(^volumeChangedBlock)(CGFloat progress);
@property (copy)void(^playRateChangedBlock)(CGFloat playRate);
@property (copy)IJKFFMoviePlayerController *(^readMediaInfoBlock)();
@property (nonatomic,assign)BOOL realtime;
- (void)changePlayOrPauseImage:(BOOL)isPlaying;
- (void)showBar;
- (void)hideBar;
- (void)setMediaProgress;
- (void)changeVolumeValue:(CGFloat)value;
- (void)showPlayRateCtl;
- (void)hidePlayRateCtl;
@end
