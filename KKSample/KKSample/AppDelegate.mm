//
//  AppDelegate.m
//  KKSample
//
//  Created by 黄栩生 on 2021/1/18.
//

#import "AppDelegate.h"
#import <KernelKit/KernelKit.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    kk_fish_hook(@"printf", (kk_replacement_function)^int(void *replaced, char * format, KKTypeList){
        int(*origin)(char*,...) = (int(*)(char*,...))replaced;
        return origin(format, KKVarList);
    });
    printf("%d, %s, %s\n", 1, "hello", "world");
    printf("%d, %s, %s\n", 1, "hello", "world");
    printf("%d, %s, %s\n", 1, "hello", "world");
    
    kk_register_exception_callback(^(NSException * exception) {
        NSLog(@"exception crash happened");
    });
    //[@{}.mutableCopy setObject:nil forKey:@""];
    
    kk_register_termination_callback(^(KKTermination * termination) {
        NSLog(@"c++ crash happened");
    });
    //throw "Division by zero condition!";
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
