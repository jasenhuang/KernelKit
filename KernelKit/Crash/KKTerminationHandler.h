//
//  KKCPPExceptionHandler.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/23.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

/**
 * greate implement from KSCrash
 * https://github.com/kstenerud/KSCrash
 *
 */

@interface KKTermination : NSObject
@property(nonatomic) NSString* name;
@property(nonatomic) NSString* desc;
@end

KK_EXTERN_C_BEGIN

typedef void(^kk_termination_callback)(KKTermination*);

/**
 * register callback for termination
 */
void kk_register_termination_callback(kk_termination_callback callback);

/**
 * unregister callback for termination
 */
void kk_unregister_termination_callback(kk_termination_callback callback);

/**
 * enable handler
 */
void kk_enable_termination_handler(bool enabled);

/**
 * is handler enabled
 */
bool is_kk_termination_handler_enabled(void);

KK_EXTERN_C_END
