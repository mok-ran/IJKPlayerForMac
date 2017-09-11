//
//  ListenMouseView.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/5.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "ListenMouseView.h"
#import "CrossAssistTool.h"
#import "IJKFFMoviePlayerController.h"
#include <Carbon/Carbon.h>

@interface ListenMouseView()
@property (nonatomic,strong)NSTrackingArea *trackingArea;
@property (nonatomic,assign)NSTrackingRectTag trackingRectTag;
@property (nonatomic, strong) NSTimer *timer;
@property (assign)NSTimeInterval latestTime;
@property (atomic,assign)BOOL isCursorIn;
@end

static CGFloat HIDE_BAR_TIME = 3.0f;
static CGFloat HIDE_CURSOR_TIME = 6.0f;

@implementation ListenMouseView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (instancetype)initWithFrame:(NSRect)frameRect{
    if(self = [super initWithFrame:frameRect]){
        [self create];
    }
    return self;
    
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    if(self = [super initWithCoder:coder]){
        [self create];
    }
    return self;
}

- (void)dealloc{
    
    [self unregisterDraggedTypes];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    
}


- (void)awakeFromNib{
    [super awakeFromNib];
    
}

- (void)updateTrackingAreas{
    [super updateTrackingAreas];
    [self registerTrackingArea];
    
    
}


#pragma mark --- setter and getter

- (NSTimer *)timer{
    
    
    if(!_timer){
        @weakify(self);
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.f repeats:YES block:^(NSTimer * _Nonnull timer) {
            @strongify(self);if(!self)return ;
            if([[NSDate date]timeIntervalSince1970] - self.latestTime > HIDE_BAR_TIME){
                if(self.hideBarBlock){
                    self.hideBarBlock();
                }
            }
            if([[NSDate date]timeIntervalSince1970] - self.latestTime > HIDE_CURSOR_TIME && self.isCursorIn){
                [NSCursor hide];
            }
            
            
            if(self.setMediaProgressBlock){
                self.setMediaProgressBlock();
            }
            
            
        }];
        [_timer fire];
    }
    return _timer;
    
}

#pragma mark --

- (void)registerTrackingArea{
    
    if(self.trackingArea){
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    
    self.trackingArea = [[NSTrackingArea alloc]initWithRect:self.bounds options:NSTrackingMouseEnteredAndExited + NSTrackingActiveInKeyWindow + NSTrackingMouseMoved owner:self userInfo:nil];
    [self addTrackingArea:self.trackingArea];
    
    
    
    [self removeTrackingRect:self.trackingRectTag];
    self.trackingRectTag = [self addTrackingRect:self.bounds
                                           owner:self
                                        userData:nil
                                    assumeInside:YES];

    

    
}

- (void)create{
    
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    [self registerTrackingArea];
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        switch (event.type) {
            case NSEventTypeKeyDown:
            {
                if(self.keyDownBlock){
                    if(event.keyCode == kVK_LeftArrow || event.keyCode == kVK_RightArrow){
                        self.latestTime = [[NSDate date]timeIntervalSince1970];
                    }
                    self.keyDownBlock(event.keyCode);
                }
            }
                
                break;
            default:
                break;
        }
        
        return event;
    }];
    
    

    
    
    @weakify(self);
    [[NSNotificationCenter defaultCenter]addObserverForName:IJKMPMoviePlayerPlaybackDidFinishNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        [self.timer invalidate];
        self.timer = nil;
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MediaPlayerBegin object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
        [self timer];
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverForName:MediaPlayerEnd object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);if(!self)return;
    }];
    
    self.latestTime = 0;
    
}

#pragma mark - action

- (void)showBarCallback{
    
    [NSCursor unhide];

    self.latestTime = [[NSDate date]timeIntervalSince1970];
    if(self.showBarBlock){
        self.showBarBlock();
    }
}


#pragma mark - Mouse 

- (void)mouseEntered:(NSEvent *)theEvent { //鼠标进入指定view
    [super mouseEntered:theEvent];
    self.isCursorIn = YES;
    [self showBarCallback];
}

- (void)mouseExited:(NSEvent *)theEvent { //移出
    [super mouseExited:theEvent];
    self.isCursorIn = NO;
    [NSCursor unhide];
}

- (void)mouseMoved:(NSEvent *)event{
    [super mouseMoved:event];
    [self showBarCallback];
}

- (void)mouseDown:(NSEvent *)event{
    [super mouseDown:event];
   
    [self showBarCallback];
}

#pragma mark - Destination Operations

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pb =[sender draggingPasteboard];
    NSArray *array=[pb types];
    if ([array containsObject:NSFilenamesPboardType]) {
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}
-(BOOL) prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pb =[sender draggingPasteboard];
    NSArray *list =[pb propertyListForType:NSFilenamesPboardType];
    for(int i = 0;i < list.count;i++){
        NSString *filename = list[i];
        BOOL isDir = NO;
        BOOL exists =  [[NSFileManager defaultManager]fileExistsAtPath:filename isDirectory:&isDir];
        if(!isDir && exists){
            self.dragFileBlock(list.lastObject);
            break;
        }
    }
    return YES;
}


@end
