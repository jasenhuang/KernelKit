//
//  KKOOM.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if TARGET_OS_IOS

@interface KKOOMTracker : NSObject

+ (KKOOMTracker*)tracker;

- (void)setup;

@end

#endif

NS_ASSUME_NONNULL_END
