//
//  CrossAssistTool.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/6/6.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#include <pthread.h>

#define  ZZ_Video_Tool_Box_Require_Min_Version 10.10

static inline float zz_get_system_version(){
    return 10.10;
}

static inline void dispatch_async_on_main_queue(void (^block)()) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

FOUNDATION_EXTERN NSString *const MediaPlayerBegin;
FOUNDATION_EXTERN NSString *const MediaPlayerEnd;

FOUNDATION_EXTERN NSString *const MediaPlayerFilenameKey;
FOUNDATION_EXTERN NSString *const MediaPlayerVolumeKey;

@interface CrossAssistTool : NSObject


@end
