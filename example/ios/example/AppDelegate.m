/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <XGPush/XGPushManager.h>
#import <XGPush.h>
#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSURL *jsCodeLocation;
  #ifdef DEBUG
    [[RCTBundleURLProvider sharedSettings] setJsLocation:@"192.168.0.154"];
  #endif    
  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"example"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  // 统计消息推送的抵达情况
  [[XGPush defaultManager] reportXGNotificationInfo:launchOptions];
  return YES;
}

// Required to register for notifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
  [XGPushManager didRegisterUserNotificationSettings:notificationSettings];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [XGPushManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

// Required for the registrationError event.
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"[XGPush] register APNS fail.\n[XGPush] reason : %@", error);
  [XGPushManager didFailToRegisterForRemoteNotificationsWithError:error];
}

// Required for the localNotification event.
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
  [XGPushManager didReceiveLocalNotification:notification];
}

/**
 收到静默消息的回调，通常此消息意味着有新数据可以读取（iOS 7.0+）
 
 @param application  UIApplication 实例
 @param userInfo 推送时指定的参数
 @param completionHandler 完成回调
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  NSLog(@"[XGPush] receive slient Message");
  NSLog(@"[XGPush] userinfo %@", userInfo);
  
  [[XGPush defaultManager] reportXGNotificationInfo:userInfo];
  [XGPushManager didReceiveRemoteMessage:userInfo fetchCompletionHandler:completionHandler];
}




@end
