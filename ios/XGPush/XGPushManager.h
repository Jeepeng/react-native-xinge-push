//
//  XGPushManager.h
//  XGPushManager
//
//  Created by Jeepeng on 16/8/5.
//  Copyright © 2016年 Jeepeng. All rights reserved.
//

#import <React/RCTEventEmitter.h>

extern NSString *const RCTRemoteNotificationReceived;

@interface XGPushManager : RCTEventEmitter

typedef void (^RCTRemoteNotificationCallback)(UIBackgroundFetchResult result);

#if !TARGET_OS_TV
+ (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
+ (void)didReceiveRemoteNotification:(NSDictionary *)notification;
+ (void)didReceiveRemoteNotification:(NSDictionary *)notification fetchCompletionHandler:(RCTRemoteNotificationCallback)completionHandler;
+ (void)didReceiveLocalNotification:(UILocalNotification *)notification;
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
#endif

@end
