//
//  OpenFileButton.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/5.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "MouseButton.h"

typedef NS_ENUM(NSInteger,MouseButtonType) {
    MouseButtonTypeOpenFile,
    MouseButtonTypePlayOrPause,
    MouseButtonTypeStop,
    MouseButtonTypeClose,
    MouseButtonTypeMin,
    MouseButtonTypeZoom,
    MouseButtonTypeVolume,
    MouseButtonTypeFastForward,
    MouseButtonTypeFastBackward,
};



@interface MouseButton()

@property (atomic,assign)BOOL opening;
@property (nonatomic,strong)NSTrackingArea *area;
@property (atomic,assign)MouseButtonType mbType;
@property (atomic,assign)MouseStat mStat;
@property (nonatomic,strong)NSArray *mouseImages;
@property (nonatomic,strong)NSArray *mouseAlternateImages;

@property (atomic,assign)BOOL isDisplaying;
@end

@implementation MouseButton

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)awakeFromNib{
    
    [super awakeFromNib];
    [self createUI];
    
}

- (void)createUI{
    
    NSImage *mouseUpImage = nil;
    NSImage *mouseDownImage = nil;
    NSImage *mouseExitedImage = nil;
    NSImage *mouseEnteredImage = nil;
    
    if([self.identifier isEqualToString:@"OpenFileButton"]){
        self.mbType = MouseButtonTypeOpenFile;
        
        mouseUpImage = [NSImage imageNamed:@"btn_openfile_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_openfile_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_openfile_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_openfile_hover"];
        
    }else if([self.identifier isEqualToString:@"PlayOrPauseBytton"]){
        self.mbType = MouseButtonTypePlayOrPause;
        mouseUpImage = [NSImage imageNamed:@"btn_play_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_play_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_play_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_play_hover"];
        
        
    }else if([self.identifier isEqualToString:@"StopButton"]){
        self.mbType = MouseButtonTypeStop;
        mouseUpImage = [NSImage imageNamed:@"btn_stop_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_stop_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_stop_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_stop_hover"];
        
        
    }else if([self.identifier isEqualToString:@"FastForwardButton"]){
        self.mbType = MouseButtonTypeFastForward;
        mouseUpImage = [NSImage imageNamed:@"btn_next_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_next_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_next_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_next_hover"];
    }else if ([self.identifier isEqualToString:@"FastBackwardButton"]){
        self.mbType = MouseButtonTypeFastBackward;
        mouseUpImage = [NSImage imageNamed:@"btn_pre_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_pre_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_pre_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_pre_hover"];
    }else if ([self.identifier isEqualToString:@"CloseButton"]){
        self.mbType = MouseButtonTypeClose;
        mouseUpImage = [NSImage imageNamed:@"btn_close_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_close_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_close_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_close_hover"];
    }else if ([self.identifier isEqualToString:@"MiniButton"]){
        self.mbType = MouseButtonTypeMin;
        mouseUpImage = [NSImage imageNamed:@"btn_min_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_min_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_min_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_min_hover"];
    }else if ([self.identifier isEqualToString:@"ZoomButton"]){
        self.mbType = MouseButtonTypeZoom;
        mouseUpImage = [NSImage imageNamed:@"btn_zoom_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_zoom_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_zoom_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_zoom_hover"];
    }else if ([self.identifier isEqualToString:@"VolumeButton"]){
        self.mbType = MouseButtonTypeZoom;
        mouseUpImage = [NSImage imageNamed:@"btn_volume_medium_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_volume_medium_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_volume_medium_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_volume_medium_hover"];
    }
    
    
    
    self.mStat = MouseStatExited;
    self.mouseImages = @[mouseExitedImage,mouseEnteredImage,mouseUpImage,mouseDownImage];
    
    if(self.mbType == MouseButtonTypePlayOrPause){
        mouseUpImage = [NSImage imageNamed:@"btn_pause_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_pause_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_pause_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_pause_hover"];
        self.mouseAlternateImages = @[mouseExitedImage,mouseEnteredImage,mouseUpImage,mouseDownImage];
    }else if (self.mbType == MouseButtonTypeVolume){
        mouseUpImage = [NSImage imageNamed:@"btn_volume_mute_hover"];
        mouseDownImage = [NSImage imageNamed:@"btn_volume_mute_pressed"];
        mouseExitedImage = [NSImage imageNamed:@"btn_volume_mute_normal"];
        mouseEnteredImage = [NSImage imageNamed:@"btn_volume_mute_hover"];
        self.mouseAlternateImages = @[mouseExitedImage,mouseEnteredImage,mouseUpImage,mouseDownImage];
    }
    

    
    self.area = [[NSTrackingArea alloc]initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited + NSTrackingActiveInKeyWindow owner:self userInfo:nil];
    [self addTrackingArea:self.area];
    [(NSButtonCell *)self.cell setHighlightsBy:NSNoCellMask];
    
    
    
}

- (void)setCurrentImage{
    
    if(self.mbType == MouseButtonTypePlayOrPause && self.isDisplaying){
        [self setImage:self.mouseAlternateImages[self.mStat]];
    }else{
        [self setImage:self.mouseImages[self.mStat]];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent { //鼠标进入指定view
    [super mouseEntered:theEvent];
    self.mStat = MouseStatEntered;
    [self setCurrentImage];
}

- (void)mouseExited:(NSEvent *)theEvent { //移出
    [super mouseExited:theEvent];
    self.mStat = MouseStatExited;
    [self setCurrentImage];
}
- (void)mouseDown:(NSEvent *)event{
    [super mouseDown:event];
    self.mStat = MouseStatDown;
    [self setCurrentImage];
    
}
- (void)mouseUp:(NSEvent *)event{
    [super mouseUp:event];
    self.mStat = MouseStatUp;
    [self setCurrentImage];
}


#pragma mark ---

- (void)changePlayOrPauseImage:(BOOL)isDisplaying{
    
    if(self.mbType != MouseButtonTypePlayOrPause)return;
    if(self.isDisplaying == isDisplaying)return;
    self.isDisplaying = isDisplaying;
    [self setCurrentImage];
}

- (void)setCurrntStat:(MouseStat)stat{
    self.mStat = stat;
    [self setCurrentImage];
}

@end
