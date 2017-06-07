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

/**
 在didFinishLaunchingWithOptions中调用，用于推送反馈.(app没有运行时，点击推送启动时)
 
 @param launchOptions didFinishLaunchingWithOptions中的userinfo参数
 @param successCallback 成功回调
 @param errorCallback 失败回调
 */
+(void)handleLaunching:(nonnull NSDictionary *)launchOptions successCallback:(nullable void (^)(void)) successCallback errorCallback:(nullable void (^)(void)) errorCallback;

/**
 在didReceiveRemoteNotification中调用，用于推送反馈。(app在运行时)
 
 @param userInfo 苹果 apns 的推送信息
 @param successCallback 成功回调
 @param errorCallback 失败回调
 */
+(void)handleReceiveNotification:(nonnull NSDictionary *)userInfo successCallback:(nullable void (^)(void)) successCallback errorCallback:(nullable void (^)(void)) errorCallback;


@end
