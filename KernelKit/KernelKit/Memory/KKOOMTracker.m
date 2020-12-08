//
//  KKOOM.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKOOMTracker.h"
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#import "KKSignalHandler.h"
#import "KKMemoryMapping.h"

@interface KKOOMTracker()
@property(nonatomic)KKMemoryMappingHandler* mapHandler;
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
    NSString* docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL* fileURL = [NSURL fileURLWithPath:[docPath stringByAppendingPathComponent:@"oom.tracker"]];
    self.mapHandler = [KKMemoryMapping kk_mmap:fileURL options:nil error:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [KKSignalHandler kk_register_signals_callback:^(kk_signal signal) {
        NSLog(@"signal occur");
        
    }];
}

- (void)handleDidEnterBackground:(NSNotification*) notif {
    
}

- (void)handleDidBecomeActive:(NSNotification*) notif {
    
}

- (void)handleWillTerminate:(NSNotification*) notif {
    
}


@end

#endif
