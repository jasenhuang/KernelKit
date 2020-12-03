//
//  KKThread.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <mach/time_value.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKThreadInfo : NSObject
@property(nonatomic) NSString* name;
@property(nonatomic) time_value_t userTime;
@property(nonatomic) time_value_t systemTime;
@property(nonatomic) double cpuUsage;
@property(nonatomic) NSInteger runState;
@property(nonatomic) NSInteger suspendCount;
@property(nonatomic) NSInteger sleepTime;
@end

@interface KKThread : NSObject

@end

NS_ASSUME_NONNULL_END
