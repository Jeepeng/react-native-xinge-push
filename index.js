/**
 * 信鸽推送
 * Created by Jeepeng on 16/8/3.
 */

import {
  Platform,
  NativeModules,
  NativeEventEmitter,
} from 'react-native';

let { XGPushManager } = NativeModules;
let XGNativeEventEmitter = new NativeEventEmitter(XGPushManager);

let _handlers = new Map();

const EventMapping = Platform.select({
  android: {
    register: 'remoteNotificationsRegistered',
    notification: 'remoteNotificationReceived',
    localNotification: 'localNotificationReceived',
    message: 'messageReceived'
  },
  ios: {
    register: 'remoteNotificationsRegistered',
    notification: 'remoteNotificationReceived',
    localNotification: 'localNotificationReceived',
  },
});

class XGPush {

  static init(accessId, accessKey) {
    let accessIdNum = Number(accessId);
    if (isNaN(accessIdNum)) {
      console.error(`[XGPush init] accessId is not a number!`);
    } else {
      if (Platform.OS === 'ios') {
        XGPushManager.startXGWithAppID(accessIdNum, accessKey);
      } else {
        XGPushManager.init(accessIdNum, accessKey);
      }
    }
  }

  static register(account) {
    if (Platform.OS === 'ios') {
      !!account && XGPushManager.bindWithAccount(account);
      return XGPushManager.requestPermissions({
        alert: true,
        badge: true,
        sound: true
      });
    } else {
      if (account) {
        return XGPushManager.bindAccount(account);
      } else {
        return XGPushManager.registerPush();
      }
    }
  }

  static setTag(tagName) {
    if (Platform.OS === 'ios') {
      return XGPushManager.bindWithTag(tagName);
    } else {
      return XGPushManager.setTag(tagName);
    }
  }

  static deleteTag(tagName) {
    if (Platform.OS === 'ios') {
      return XGPushManager.unbindWithTag(tagName);
    } else {
      return XGPushManager.deleteTag(tagName);
    }
  }

  static unRegister() {
    if (Platform.OS === 'ios') {
      return XGPushManager.stopXGNotification();
    } else {
      return XGPushManager.unregisterPush();
    }
  }

  static setApplicationIconBadgeNumber(number) {
    XGPushManager.setApplicationIconBadgeNumber(number);
  }

  static getApplicationIconBadgeNumber(callback) {
    XGPushManager.getApplicationIconBadgeNumber(callback);
  }

  static checkPermissions(callback) {
    if (Platform.OS === 'ios') {
      return XGPushManager.checkPermissions(callback);
    }
  }

  static getInitialNotification() {
    return XGPushManager.getInitialNotification();
  }

  static onLocalNotification(callback) {
    this.addEventListener('localNotification', callback)
  }

  /**
   * 透传消息 Android only
   */
  static onMessage(callback) {
    if (Platform.OS === 'android') {
      this.addEventListener('message', callback)
    }
  }

  static addEventListener(eventType, callback) {
    let event = EventMapping[eventType];
    if (!event) {
      console.warn('XGPush only supports `notification`, `register` and `localNotification` events');
      return;
    }
    let listener = XGNativeEventEmitter.addListener(event, (data) => {
      let result = data;
      if (eventType === 'register') {
        result = data['deviceToken'];
      }
      callback(result);
    });
    _handlers.set(callback, listener);
  }

  static removeEventListener(eventType, callback) {
    if (!EventMapping[eventType]) {
      console.warn('XGPush only supports `notification`, `register` and `localNotification` events');
      return;
    }
    let listener = _handlers.get(callback);
    if (listener) {
      listener.remove();
      _handlers.delete(callback);
    }
  }

  static enableDebug(isDebug = true) {
    if (Platform.OS === 'ios') {
      XGPushManager.setEnableDebug(isDebug);
    } else {
      XGPushManager.enableDebug(isDebug);
    }
  }

  static isEnableDebug() {
    return XGPushManager.isEnableDebug();
  }

  /**************************** android only ************************/

  /**
   * 获取设备的token，只有注册成功才能获取到正常的结果
   */
  static getToken() {
    if (Platform.OS === 'android') {
      return XGPushManager.getToken(isEnable);
    } else {
      return Promise.resolve();
    }
  }

  /**
   * 设置上报通知栏是否关闭 默认打开
   */
  static setReportNotificationStatusEnable() {
    if (Platform.OS === 'android') {
      XGPushManager.setReportNotificationStatusEnable();
    }
  }

  /**
   * 设置上报APP 列表，用于智能推送 默认打开
   */
  static setReportApplistEnable() {
    if (Platform.OS === 'android') {
      XGPushManager.setReportApplistEnable();
    }
  }

  /**
   * 打开第三方推送（在 registerPush 之前调用）
   * @param isEnable
   */
  static enableOtherPush(isEnable = true) {
    if (Platform.OS === 'android') {
      XGPushManager.enableOtherPush(isEnable);
    }
  }

  /**
   * 打开华为通道debug模式
   * @param isDebug
   */
  static setHuaweiDebug(isDebug = true) {
    if (Platform.OS === 'android') {
      XGPushManager.setHuaweiDebug(isDebug);
    }
  }

  static initXiaomi(appId, appKey) {
    if (Platform.OS === 'android') {
      XGPushManager.initXiaomi(appId, appKey);
    }
  }

  static initMeizu(appId, appKey) {
    if (Platform.OS === 'android') {
      XGPushManager.initMeizu(appId, appKey);
    }
  }

  /**************************** ios only ************************/


}

export default XGPush;
