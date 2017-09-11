//
//  OpenNetworkWindowCtl.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/11.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OpenNetworkWindowCtl : NSWindowController
@property (nonatomic,copy)void(^openBlock)(NSString *url);
@property (nonatomic,copy)void(^cancelBlock)();
@end
