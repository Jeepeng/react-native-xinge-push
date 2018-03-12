## TODO
- [x] 升级信鸽Android SDK 到 v3.2.2
- [x] 适配华为官方推送通道
- [ ] 适配小米官方推送通道
- [ ] 适配魅族官方推送通道
- [ ] 升级信鸽iOS SDK 到 v3.1.0

## 版本对照表
react-native-xinge-push | 信鸽SDK（Android） | 信鸽SDK（iOS）
---|---|---
0.4 | 3.2.2 | 2.5.0
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
#import <XGPush/XGPushManager.h>

// ...

// Required to register for notifications
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
  [XGPushManager didRegisterUserNotificationSettings:notificationSettings];
}
// Required for the register event.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  [XGPushManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}
// Required for the notification event. You must call the completion handler after handling the remote notification.
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  UIApplicationState state = [application applicationState];
  BOOL isClicked = (state != UIApplicationStateActive);
  NSMutableDictionary *remoteNotification = [NSMutableDictionary dictionaryWithDictionary:userInfo];
  if(isClicked) {
    remoteNotification[@"clicked"] = @YES;
  }
  [XGPushManager didReceiveRemoteNotification:remoteNotification fetchCompletionHandler:completionHandler];
  // 统计收到推送的设备
  [XGPushManager handleReceiveNotification:remoteNotification successCallback:^{
    NSLog(@"[XGPush] Handle receive success");
  } errorCallback:^{
    NSLog(@"[XGPush] Handle receive error");
  }];
}
// Required for the registrationError event.
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  [XGPushManager didFailToRegisterForRemoteNotificationsWithError:error];
}
// Required for the localNotification event.
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
  [XGPushManager didReceiveLocalNotification:notification];
}
```

## Example

see `example` folder for more details
