/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

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

  initPush() {
    // 初始化
    if(Platform.OS === 'android') {
      // 请将1111111111修改为APP的AccessId，10位数字
      // 请将YOUR_ACCESS_KEY修改为APP的AccessKey
      XGPush.init(2100209996, 'AHW931HVZ42A');
    } else {
      // 请将1111111111修改为APP的AccessId，10位数字
      // 请将YOUR_ACCESS_KEY修改为APP的AccessKey
      XGPush.init(2200209997, 'ITD46N87JA4K');
    }

    XGPush.setHuaweiDebug(true);

    // 小米
    XGPush.initXiaomi('appId', 'appKey');

    // 魅族
    XGPush.initMeizu('appId', 'appKey');

    // 华为请到 build.gradle manifestPlaceholders 配置

    // 第三方推送开关（华为、小米、魅族）
    XGPush.enableOtherPush(true);

    // 注册
    XGPush.register('jeepeng')
      .then(result => {
        // do something
      })
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
    if(notification.clicked === true) {
      alert('app处于后台时收到通知' + JSON.stringify(notification));
    } else {
      alert('app处于前台时收到通知' + JSON.stringify(notification));
    }
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
    paddingTop: 20,
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
