//
//  KKOOM.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

#if TARGET_OS_IOS

@interface KKOOMTracker : NSObject

+ (KKOOMTracker*)tracker;

- (void)setup;

@end

#endif

