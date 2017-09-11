//
//  EventSendManager.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/11.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "EventSendManager.h"

@interface EventSendManager()

@end
static EventSendManager *_self = nil;
@implementation EventSendManager

#pragma mark --- sys

+ (instancetype)shareManager{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _self = [[self alloc]init];
    });
    return _self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _self = [super allocWithZone:zone];
    });
    return _self;
    
}

- (id)copy{
    return [[self class]shareManager];
}

- (id)mutableCopy{
    return [[self class]shareManager];
}

- (instancetype)init{
    
    if(self = [super init]){
        [self create];
    }
    return self;
}

#pragma mark -- 

- (void)create{
    
}
@end
