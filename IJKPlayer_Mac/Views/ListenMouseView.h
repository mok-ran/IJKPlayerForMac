//
//  ListenMouseView.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/5.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ListenMouseView : NSView
@property (nonatomic,copy)void(^dragFileBlock)(NSString *filename);
@property (nonatomic,copy)void(^keyDownBlock)(short keyCode);
@property (nonatomic,copy)void(^setMediaProgressBlock)();
@property (nonatomic,copy)void(^hideBarBlock)();
@property (nonatomic,copy)void(^showBarBlock)();

@end
