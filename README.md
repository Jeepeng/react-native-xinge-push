# react-native-xinge-push
信鸽推送React Native版

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
```xml
  <!-- 【必须】 信鸽receiver广播接收 -->
  <receiver android:name="com.tencent.android.tpush.XGPushReceiver"
      android:process=":xg_service_v3" >
      <intent-filter android:priority="0x7fffffff" >
          <!-- 【必须】 信鸽SDK的内部广播 -->
          <action android:name="com.tencent.android.tpush.action.SDK" />
          <action android:name="com.tencent.android.tpush.action.INTERNAL_PUSH_MESSAGE" />
          <!-- 【必须】 系统广播：开屏和网络切换 -->
          <action android:name="android.intent.action.USER_PRESENT" />
          <action android:name="android.net.conn.CONNECTIVITY_CHANGE" />
          <!-- 【可选】 一些常用的系统广播，增强信鸽service的复活机会，请根据需要选择。当然，你也可以添加APP自定义的一些广播让启动service -->
          <action android:name="android.bluetooth.adapter.action.STATE_CHANGED" />
          <action android:name="android.intent.action.ACTION_POWER_CONNECTED" />
          <action android:name="android.intent.action.ACTION_POWER_DISCONNECTED" />
      </intent-filter>
  </receiver>

  <receiver android:name="com.jeepeng.react.xgpush.receiver.MessageReceiver"
      android:exported="true" >
      <intent-filter>
          <!-- 接收消息透传 -->
          <action android:name="com.tencent.android.tpush.action.PUSH_MESSAGE" />
          <!-- 监听注册、反注册、设置/删除标签、通知被点击等处理结果 -->
          <action android:name="com.tencent.android.tpush.action.FEEDBACK" />
      </intent-filter>
  </receiver>

  <!-- 【必须】 (2.30及以上版新增)展示通知的activity -->
  <!-- 【注意】 如果被打开的activity是启动模式为SingleTop，SingleTask或SingleInstance，请根据通知的异常自查列表第8点处理-->
  <activity
      android:name="com.tencent.android.tpush.XGPushActivity"
      android:exported="false" >
      <intent-filter>
          <!-- 若使用AndroidStudio，请设置android:name="android.intent.action"-->
          <action android:name="" />
      </intent-filter>
  </activity>

  <!-- 【必须】 信鸽service -->
  <service
      android:name="com.tencent.android.tpush.service.XGPushServiceV3"
      android:exported="true"
      android:persistent="true"
      android:process=":xg_service_v3" />
  <!-- 【必须】 提高service的存活率 -->
  <service
      android:name="com.tencent.android.tpush.rpc.XGRemoteService"
      android:exported="true">
      <intent-filter>
          <!-- 【必须】 请修改为当前APP包名 .PUSH_ACTION, 如demo的包名为：com.qq.xgdemo -->
          <action android:name="您的包名.PUSH_ACTION" />
      </intent-filter>
  </service>
  <!-- 【必须】 增强xg_service存活率 -->
  <service
      android:name="com.tencent.android.tpush.service.XGDaemonService"
      android:process=":xg_service_v3" />

  <!-- 【必须】 【注意】authorities修改为 包名.AUTH_XGPUSH, 如demo的包名为：com.qq.xgdemo-->
  <provider
      android:name="com.tencent.android.tpush.XGPushProvider"
      android:authorities="您的包名.AUTH_XGPUSH"
      android:exported="true"/>
  <!-- 【必须】 【注意】authorities修改为 包名.TPUSH_PROVIDER, 如demo的包名为：com.qq.xgdemo-->
  <provider
      android:name="com.tencent.android.tpush.SettingsContentProvider"
      android:authorities="您的包名.TPUSH_PROVIDER"
      android:exported="false" />
  <!-- 【必须】 【注意】authorities修改为 包名.TENCENT.MID.V3, 如demo的包名为：com.qq.xgdemo-->
  <provider
      android:name="com.tencent.mid.api.MidProvider"
      android:authorities="您的包名.TENCENT.MID.V3"
      android:exported="true" >
  </provider>

  <!-- 【必须】 请将YOUR_ACCESS_ID修改为APP的AccessId，“21”开头的10位数字，中间没空格 -->
  <meta-data
      android:name="XG_V2_ACCESS_ID"
      android:value="YOUR_ACCESS_ID" />
  <!-- 【必须】 请将YOUR_ACCESS_KEY修改为APP的AccessKey，“A”开头的12位字符串，中间没空格 -->
  <meta-data
      android:name="XG_V2_ACCESS_KEY"
      android:value="YOUR_ACCESS_KEY" />
```

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
