//
//  KeepWake.m
//  IJKPlayer_Mac
//
//  Created by mini on 2017/9/11.
//  Copyright © 2017年 mini. All rights reserved.
//

#import "KeepWake.h"
#import <AppKit/AppKit.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

@interface KeepWake()

@end

static KeepWake *_self = nil;
@implementation KeepWake

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

- (void)dealloc{
    [[[NSWorkspace sharedWorkspace]notificationCenter]removeObserver:self];
}

#pragma mark ---

- (void)create{
    
    [self addNotifications];
    
}

- (void) receiveSleepNote: (NSNotification*) note
{
    NSLog(@"receiveSleepNote: %@", [note name]);
    
    if(self.keepWake){
        // kIOPMAssertionTypeNoDisplaySleep prevents display sleep,
        
        // kIOPMAssertionTypeNoIdleSleep prevents idle sleep
        
        //reasonForActivity is a descriptive string used by the system whenever it needs
        
        //  to tell the user why the system is not sleeping. For example,
        
        //  "Mail Compacting Mailboxes" would be a useful string.
        
        //  NOTE: IOPMAssertionCreateWithName limits the string to 128 characters.
        
        CFStringRef reasonForActivity= CFSTR("Describe Activity Type");
        
        IOPMAssertionID assertionID;
        
        IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleDisplaySleep,
                                                       
                                                       kIOPMAssertionLevelOn, reasonForActivity, &assertionID);
        
        if (success == kIOReturnSuccess)
            
        {
            
            //Add the work you need to do without
            
            //  the system sleeping here.
            
            success = IOPMAssertionRelease(assertionID);
            
            //The system will be able to sleep again.
            
        }
        
    
    }
}

- (void) receiveWakeNote: (NSNotification*) note
{
    NSLog(@"receiveWakeNote: %@", [note name]);
}

- (void) addNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default
    // notification center. You will not receive sleep/wake notifications if you file
    //with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceScreensDidSleepNotification object: NULL];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
}



#pragma mark -- out api


@end
