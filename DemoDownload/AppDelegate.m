//
//  AppDelegate.m
//  DemoDownload
//
//  Created by yingxin ye on 2017/4/25.
//  Copyright © 2017年 yingxin ye. All rights reserved.
//

#import "AppDelegate.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DownloadManager.h"
static NSString *const PurpleTag = @"PurpleTag";

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *toPath = [DownloadManager manager].storagePath;
    UIColor *purple = [UIColor colorWithRed:(64/255.0) green:(0/255.0) blue:(128/255.0) alpha:1.0];
    DDTTYLogger *logger = [DDTTYLogger sharedInstance];
    [logger setForegroundColor:purple backgroundColor:nil forTag:PurpleTag];
    [DDLog addLogger:logger];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *cfg = [path stringByAppendingPathComponent:@"MDM.mobileconfig"];
    NSString *cfg1 = [path stringByAppendingPathComponent:@"MDM1.mobileconfig"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSString *cfgPath = [toPath stringByAppendingPathComponent:@"MDM.mobileconfig"];
    NSString *cfgPath1 = [toPath stringByAppendingPathComponent:@"MDM1.mobileconfig"];
    
    [fileManager removeItemAtPath:cfgPath error:&error];
    [fileManager removeItemAtPath:cfgPath1 error:&error];
    [fileManager copyItemAtPath:cfg toPath:cfgPath error:&error];
    [fileManager copyItemAtPath:cfg1 toPath:cfgPath1 error:&error];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
