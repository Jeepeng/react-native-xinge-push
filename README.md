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

```js

import React, { Component } from 'react';
import {
  Platform,
  StyleSheet,
  Text,
  View,
  TouchableNativeFeedback,
  TouchableHighlight
} from 'react-native';
import XGPush from 'react-native-xinge-push';

const Touchable = Platform.OS === 'android' ? TouchableNativeFeedback : TouchableHighlight;

class Example extends Component {

  constructor() {
    super();
    this.state = {
      isDebug: false
    };
    this._enableDebug = this._enableDebug.bind(this);
    this._isEnableDebug = this._isEnableDebug.bind(this);

    // 初始化推送
    this.initPush();
  }

  async initPush() {
    let accessId;
    let accessKey;
    if(Platform.OS === 'ios') {
      accessId = 1111111111; // 请将1111111111修改为APP的AccessId，10位数字
      accessKey = "YOUR_ACCESS_KEY"; // 请将YOUR_ACCESS_KEY修改为APP的AccessKey
    } else {
      accessId = 2222222222;
      accessKey = "YOUR_ACCESS_KEY";
    }
    // 初始化
    XGPush.init(accessId, accessKey);

    // 注册
    XGPush.register('jeepeng')
      .then(result => result)
      .catch(err => {
        console.log(err);
      });
  }

  componentDidMount() {
    XGPush.addEventListener('register', this._onRegister);
    XGPush.addEventListener('message', this._onMessage);
    XGPush.addEventListener('notification', this._onNotification);
  }

  componentWillUnmount() {
    XGPush.removeEventListener('register', this._onRegister);
    XGPush.removeEventListener('message', this._onMessage);
    XGPush.removeEventListener('notification', this._onNotification);
  }

  /**
   * 注册成功
   * @param deviceToken
   * @private
   */
  _onRegister(deviceToken) {
    alert('onRegister: ' + deviceToken);
    // 在ios中，register方法是向apns注册，如果要使用信鸽推送，得到deviceToken后还要向信鸽注册
    XGPush.registerForXG(deviceToken);
  }

  /**
   * 透传消息到达
   * @param message
   * @private
   */
  _onMessage(message) {
    alert('收到透传消息: ' + message.content);
  }

  /**
   * 通知到达
   * @param notification
   * @private
   */
  _onNotification(notification) {
    alert(JSON.stringify(notification));
  }

  /**
   * 获取初始通知（点击通知后）
   * @private
   */
  _getInitialNotification() {
    XGPush.getInitialNotification().then((result) => {
      alert(JSON.stringify(result));
    });
  }

  _enableDebug() {
    XGPush.enableDebug(!this.state.isDebug);
  }

  _isEnableDebug() {
    XGPush.isEnableDebug().then(result => {
      this.setState({
        isDebug: result
      });
      alert(result);
    });
  }

  _setApplicationIconBadgeNumber(number = 0) {
    XGPush.setApplicationIconBadgeNumber(number);
  }

  _getApplicationIconBadgeNumber() {
    XGPush.getApplicationIconBadgeNumber((number) => alert(number));
  }

  render() {
    return (
      <View style={styles.container}>
        <Touchable underlayColor="#ddd" onPress={this._getInitialNotification}>
          <View style={styles.item}>
            <Text>getInitialNotification</Text>
          </View>
        </Touchable>
        <Touchable onPress={ ()=> { this._enableDebug() }} underlayColor="#ddd">
          <View style={styles.item}>
            <Text>enableDebug</Text>
          </View>
        </Touchable>
        <Touchable onPress={ ()=> { this._isEnableDebug() }} underlayColor="#ddd">
          <View style={styles.item}>
            <Text>isEnableDebug</Text>
          </View>
        </Touchable>
        <Touchable onPress={ ()=> { this._setApplicationIconBadgeNumber(99) }} underlayColor="#ddd">
          <View style={styles.item}>
            <Text>setApplicationIconBadgeNumber: 99</Text>
          </View>
        </Touchable>
        <Touchable onPress={ ()=> { this._getApplicationIconBadgeNumber() }} underlayColor="#ddd">
          <View style={styles.item}>
            <Text>getApplicationIconBadgeNumber</Text>
          </View>
        </Touchable>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  list: {
    marginTop: 15,
    backgroundColor: '#fff',
  },
  item: {
    height: 45,
    alignItems: 'center',
    justifyContent: 'center',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#efefef'
  },
});

export default Example;

```

see `example` folder for more details
