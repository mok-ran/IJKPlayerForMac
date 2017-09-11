//
//  PlayerControlBar.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/6.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "PlayerControlBar.h"
#import "MouseButton.h"
#import <Quartz/Quartz.h>
#import "IJKMediaPlayback.h"
#import "IJKFFMoviePlayerController.h"
#import "CrossAssistTool.h"

@interface PlayerControlBar ()

@property (weak) IBOutlet NSTextField *leftTimeLabel;
@property (weak) IBOutlet MouseButton *playOrPauseButton;
@property (weak) IBOutlet NSSlider *progressView;

@property (weak) IBOutlet MouseButton *stopButton;
@property (weak) IBOutlet NSButton *volumeButton;
@property (weak) IBOutlet NSSlider *volumeSlider;
@property (weak) IBOutlet NSTextField *volumeLabel;

@property (weak) IBOutlet NSPopUpButton *popUpButton;

@property (strong) NSArray *playRateValues;
@end



@implementation PlayerControlBar

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self createUI];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)createUI{
    

    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor colorWithWhite:0.f alpha:0.75].CGColor;
//    self.view.layer.masksToBounds = YES;
//    self.view.layer.cornerRadius = 6;
    
    self.progressView.trackFillColor = [NSColor whiteColor];
    
    self.leftTimeLabel.stringValue = @"00:00:00/00:00:00";
    self.progressView.floatValue = 0.0f;
    [self.popUpButton removeAllItems];
    NSArray *playRateValues = @[@0.25,@0.5,@0.75,@1,@1.5,@2,@3];
    self.playRateValues = playRateValues;
    for(int i = 0; i < playRateValues.count;++i){
        [self.popUpButton addItemWithTitle:[NSString stringWithFormat:@"x%@",playRateValues[i]]];
    }
    [self.popUpButton selectItemAtIndex:3];
    
    
    @weakify(self);
    [[NSNotificationCenter defaultCenter]addObserverForName:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        self.leftTimeLabel.stringValue = @"00:00:00/00:00:00";
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MediaPlayerBegin object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        [self.playOrPauseButton changePlayOrPauseImage:YES];
        if(note.userInfo){
            CGFloat volume = [note.userInfo[MediaPlayerVolumeKey] floatValue];
            self.volumeSlider.floatValue = volume * 100;
        }else{
            self.volumeSlider.floatValue = 90;
        }
        self.volumeLabel.stringValue = [NSString stringWithFormat:@"%ld%%",lround(self.volumeSlider.floatValue)];
        
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MediaPlayerEnd object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        self.view.hidden = YES;
    }];
    
    

}


#pragma mark --  setter and getter

- (void)setRealtime:(BOOL)realtime{
    _realtime = realtime;
    self.progressView.hidden = realtime;
}

#pragma mark ---

-(NSString *)timeStr:(NSTimeInterval)timeNum{
    
    NSString *timeStr = @"00:00:00";
    NSInteger time = lround(timeNum);
    if(time < 60){
        timeStr = [NSString stringWithFormat:@"00:00:%02ld",time];
    }else if (time >= 60 && time < 3600){
        NSInteger mins = time / 60;
        NSInteger secs = time % 60;
        timeStr = [NSString stringWithFormat:@"00:%02ld:%02ld",mins,secs];
    }else if (time >= 3600){
        NSInteger hours = time / 3600;
        NSInteger mins = time % 3600 / 60;
        NSInteger secs = time % 60;
        timeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",hours,mins,secs];
    }
    return timeStr;
}

- (void)setMediaProgress{
    
    if(self.view.hidden)return;

    IJKFFMoviePlayerController *player = nil;
    if(self.readMediaInfoBlock){
        player = self.readMediaInfoBlock();
    }
    if(player){
        
        NSString *currentStr = [self timeStr:player.currentPlaybackTime];
        
        if(self.realtime){
            self.leftTimeLabel.stringValue = currentStr;
        }else{
            NSString *durationStr = [self timeStr:player.duration];
            self.leftTimeLabel.stringValue = [NSString stringWithFormat:@"%@/%@",currentStr,durationStr];
        }
        
        self.progressView.floatValue = player.currentPlaybackTime / player.duration * 100;

    }else{
        self.leftTimeLabel.stringValue = @"00:00:00/00:00:00";
        self.progressView.floatValue = 0.0f;
    }
    
}


- (void)showBar{
    
    //if(self.view.hidden == NO)return;
    
    
//    self.view.layer.opacity = 0.0f;
    self.view.hidden = NO;
    [self setMediaProgress];
    [self.view.superview addSubview:self.view positioned:NSWindowAbove relativeTo:self.view.superview.subviews.lastObject];
//    CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    basic.beginTime = CACurrentMediaTime();
//    basic.duration = 0.5;
//    basic.toValue = @(1.0f);
//    basic.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//    [self.view.layer addAnimation:basic forKey:nil];
    
}

- (void)hideBar{
    
   //if(self.view.hidden == YES)return;
    
//    CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    basic.beginTime = CACurrentMediaTime();
//    basic.duration = 0.5;
//    basic.toValue = @(0.0f);
//    basic.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//    [self.view.layer addAnimation:basic forKey:nil];
    
    self.view.hidden = YES;
//    self.view.layer.opacity = 1.0f;
    
}


- (void)changePlayOrPauseImage:(BOOL)isPlaying{
    
    [self.playOrPauseButton changePlayOrPauseImage:isPlaying];
}

- (void)showPlayRateCtl{
    self.popUpButton.hidden = NO;
}
- (void)hidePlayRateCtl{
    self.popUpButton.hidden = YES;
}

#pragma mark ---- action

- (IBAction)playOrPauseClick:(MouseButton *)sender {
    
    if(self.playOrPauseBlock){
        self.playOrPauseBlock();
    }
}

- (IBAction)stopClick:(MouseButton *)sender {
    if(self.stopBlock){
        self.stopBlock();
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sender setCurrntStat:MouseStatExited];
    });
    
}

- (IBAction)progressChanged:(NSSlider *)sender {
    
    if(self.progressChangedBlock){
        self.progressChangedBlock(sender.floatValue / 100);
    }
    
}

- (IBAction)volumeClick:(MouseButton *)sender {
    
    
    
}
- (IBAction)volumeSliderChanged:(NSSlider *)sender {
    if(self.volumeChangedBlock){
        self.volumeChangedBlock(sender.floatValue/100);
    }
    self.volumeLabel.stringValue = [NSString stringWithFormat:@"%ld%%",lround(sender.floatValue)];
}

- (IBAction)popUpClick:(NSPopUpButton *)sender {
    if(self.playRateChangedBlock){
        self.playRateChangedBlock([self.playRateValues[sender.indexOfSelectedItem]floatValue]);
    }
}

- (void)changeVolumeValue:(CGFloat)value{
    CGFloat curVaule = MAX(MIN(value, 1.0f), 0.0f) * 100;
    if(fabs(curVaule - self.volumeSlider.floatValue) < 0.01){
        return;
    }
    self.volumeSlider.floatValue = curVaule;
    dispatch_async_on_main_queue(^{
        [self volumeSliderChanged:self.volumeSlider];
    });
    
}

@end
