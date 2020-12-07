//
//  KKOOM.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKOOMTracker.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>

@interface KKOOMTracker()

@end

@implementation KKOOMTracker

+ (KKOOMTracker*)tracker {
    static KKOOMTracker* _tracker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _tracker = [KKOOMTracker new];
    });
    return _tracker;
}

- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)handleDidEnterBackground:(NSNotification*) notif {
    
}

- (void)handleDidBecomeActive:(NSNotification*) notif {
    
}



@end

#endif
