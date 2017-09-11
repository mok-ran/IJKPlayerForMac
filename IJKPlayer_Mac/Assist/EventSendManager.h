//
//  EventSendManager.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/11.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface EventSendManager : NSObject
@property (nonatomic,copy)void(^openFileBlock)(NSMenuItem *item);
@property (nonatomic,copy)void(^openNetworkBlock)(NSMenuItem *item);
+ (instancetype)shareManager;
@end
