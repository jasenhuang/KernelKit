//
//  KKCrashHandler.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/17.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

typedef void(^kk_exception_callback)(NSException*);

/**
 * register callback for exception
 */
void kk_register_exception_callback(kk_exception_callback callback);

/**
 * unregister callback for exception
 */
void kk_unregister_exception_callback(kk_exception_callback callback);
