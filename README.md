## TODO
- [x] 升级信鸽Android SDK 到 v3.2.2
- [x] 适配华为官方推送通道
- [x] 适配小米官方推送通道
- [x] 适配魅族官方推送通道
- [ ] 升级信鸽iOS SDK 到 v3.1.0

## 版本对照表
react-native-xinge-push | 信鸽SDK（Android） | 信鸽SDK（iOS）
---|---|---
0.4～0.5 | 3.2.2 | 2.5.0
0.3 | 3.1.0 | 2.5.0


## install
```
npm install --save react-native-xinge-push
```

## link

```
react-native link react-native-xinge-push
```

## usage
### Android
待更新

#### 华为推送通道集成指南
1. 确认已在信鸽管理台中「应用配置-厂商&海外通道」中填写相关的应用信息。通常，相关配置将在1个小时后生效，请您耐心等待，在生效后再进行下一个步骤
2. 将集成好的App（测试版本）安装在测试机上，并且运行App
3. 保持App在前台运行，尝试对设备进行单推/全推
4. 如果应用收到消息，将App退到后台，并且杀掉所有App进程
5. 再次进行单推/全推，如果能够收到推送，则表明厂商通道集成成功

###### 注意事项
如果在EMUI 8.0（Android 8）上，出现发通知成功但通知栏不显示的情况，并在Logcat看到以下错误：
```
E/NotificationService: No Channel found for pkg=com.jeepeng.push, channelId=null, id=995033369, tag=null, opPkg=com.huawei.android.pushagent, callingUid=10060, userId=0, incomingUserId=0, notificationUid=10261, notification=Notification(channel=null pri=0 contentView=null vibrate=null sound=default tick defaults=0x1 flags=0x10 color=0x00000000 vis=PRIVATE)
```

需要将`targetSdkVersion`[降到25](https://stackoverflow.com/questions/45668079/notificationchannel-issue-in-android-o)



### iOS
AppDelegate.m:

```oc
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

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"[XGDemo] device token is %@", [[XGPushTokenManager defaultTokenManager] deviceTokenString]);
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"[XGDemo] register APNS fail.\n[XGDemo] reason : %@", error);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"registerDeviceFailed" object:nil];
}

/**
 收到通知消息的回调，通常此消息意味着有新数据可以读取（iOS 7.0+）
 
 @param application  UIApplication 实例
 @param userInfo 推送时指定的参数
 @param completionHandler 完成回调
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  NSLog(@"[XGDemo] receive slient Notification");
  NSLog(@"[XGDemo] userinfo %@", userInfo);
  UIApplicationState state = [application applicationState];
  BOOL isClicked = (state != UIApplicationStateActive);
  NSMutableDictionary *remoteNotification = [NSMutableDictionary dictionaryWithDictionary:userInfo];
  if(isClicked) {
    remoteNotification[@"clicked"] = @YES;
    remoteNotification[@"background"] = @YES;
  }
  [[XGPush defaultManager] reportXGNotificationInfo:remoteNotification];
  completionHandler(UIBackgroundFetchResultNewData);
}

// iOS 10 新增 API
// iOS 10 会走新 API, iOS 10 以前会走到老 API
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// App 用户点击通知
// App 用户选择通知中的行为
// App 用户在通知中心清除消息
// 无论本地推送还是远程推送都会走这个回调
- (void)xgPushUserNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
	NSLog(@"[XGDemo] click notification");
	if ([response.actionIdentifier isEqualToString:@"xgaction001"]) {
		NSLog(@"click from Action1");
	} else if ([response.actionIdentifier isEqualToString:@"xgaction002"]) {
		NSLog(@"click from Action2");
	}
	
	[[XGPush defaultManager] reportXGNotificationResponse:response];
	
	completionHandler();
}

// App 在前台弹通知需要调用这个接口
- (void)xgPushUserNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
	[[XGPush defaultManager] reportXGNotificationInfo:notification.request.content.userInfo];
	completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}
#endif


@end

```

## Example

see `example` folder for more details
