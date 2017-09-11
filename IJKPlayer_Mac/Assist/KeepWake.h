//
//  KeepWake.h
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/11.
//  Copyright © 2017年 mini. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeepWake : NSObject
@property (atomic,assign)BOOL keepWake;
+ (instancetype)shareManager;
@end
