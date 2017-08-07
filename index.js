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
      XGPushManager.startApp(accessIdNum, accessKey);
    }
  }
  
  static register(account) {
    if (Platform.OS === 'ios') {
      !!account && XGPushManager.setAccount(account);
      return XGPushManager.requestPermissions({
        alert: true,
        badge: true,
        sound: true
      });
    } else {
      return XGPushManager.registerPush(account);
    }
  }
  
  /**
   * ios only
   * @param deviceToken
   * @returns {*}
   */
  static registerForXG(deviceToken) {
    if (Platform.OS === 'ios') {
      return XGPushManager.registerDevice(deviceToken, null);
    } else {
      return new Promise((resolve, reject) => {
        //reject('ios only');
      });
    }
  }
  
  static setTag(tagName) {
    return XGPushManager.setTag(tagName);
  }
  
  static deleteTag(tagName) {
    if (Platform.OS === 'ios') {
      return XGPushManager.delTag(tagName);
    } else {
      return XGPushManager.deleteTag(tagName);
    }
  }
  
  static unRegister() {
    if (Platform.OS === 'ios') {
      return XGPushManager.unRegisterDevice();
    } else {
      return XGPushManager.unRegisterPush();
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
    XGPushManager.enableDebug(isDebug);
  }
  
  static isEnableDebug() {
    return XGPushManager.isEnableDebug();
  }
}

export default XGPush;
