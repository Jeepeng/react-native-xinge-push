package com.jeepeng.react.xgpush;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.support.annotation.Nullable;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.tencent.android.tpush.XGIOperateCallback;
import com.tencent.android.tpush.XGLocalMessage;
import com.tencent.android.tpush.XGPushConfig;
import com.tencent.android.tpush.XGPushManager;
import com.tencent.android.tpush.encrypt.Rijndael;

/**
 * 信鸽推送
 * Created by Jeepeng on 16/8/3.
 */
public class PushModule extends ReactContextBaseJavaModule implements ActivityEventListener, LifecycleEventListener {

    public static final String MODULE_NAME = "XGPushManager";

    private Context reactContext;

    public PushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        reactContext.addActivityEventListener(this);
        reactContext.addLifecycleEventListener(this);
        this.reactContext = reactContext;
        registerReceivers();
    }

    @Override
    public String getName() {
        return MODULE_NAME;
    }

    private void sendEvent(String eventName, @Nullable WritableMap params) {
        getReactApplicationContext()
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    private void registerReceivers() {
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(Constants.ACTION_ON_REGISTERED);
        intentFilter.addAction(Constants.ACTION_ON_TEXT_MESSAGE);
        intentFilter.addAction(Constants.ACTION_ON_NOTIFICATION_CLICKED);
        intentFilter.addAction(Constants.ACTION_ON_NOTIFICATION_SHOWED);

        reactContext.registerReceiver(new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                WritableMap params = Arguments.createMap();
                switch (intent.getAction()){
                    case Constants.ACTION_ON_REGISTERED:
                        intent.getBundleExtra("notification");
                        String token = intent.getStringExtra("token");
                        params.putString("deviceToken", token);

                        sendEvent(Constants.EVENT_REGISTERED, params);
                        break;
                    case Constants.ACTION_ON_TEXT_MESSAGE:
                        String title = intent.getStringExtra("title");
                        String content = intent.getStringExtra("content");
                        String customContent = intent.getStringExtra("customContent");
                        params.putString("title", title);
                        params.putString("content", content);
                        params.putString("custom_content", customContent);

                        sendEvent(Constants.EVENT_MESSAGE_RECEIVED, params);
                        break;
                    case Constants.ACTION_ON_NOTIFICATION_SHOWED:
                        params.putString("title", intent.getStringExtra("title"));
                        params.putString("content", intent.getStringExtra("content"));
                        params.putString("custom_content", intent.getStringExtra("customContent"));

                        sendEvent(Constants.EVENT_REMOTE_NOTIFICATION_RECEIVED, params);
                        break;
                    case Constants.ACTION_ON_NOTIFICATION_CLICKED:
                        params.putString("title", intent.getStringExtra("title"));
                        params.putString("content", intent.getStringExtra("content"));
                        params.putString("custom_content", intent.getStringExtra("customContent"));

                        sendEvent(Constants.ACTION_ON_NOTIFICATION_CLICKED, params);
                        break;
                    default:
                        break;
                }


            }
        }, intentFilter);
    }

    /**
     * 开启logcat输出，方便debug，发布时请关闭
     */
    @ReactMethod
    public void enableDebug(boolean isDebug) {
        XGPushConfig.enableDebug(this.reactContext, isDebug);
    }

    /**
     * 开启logcat输出，方便debug，发布时请关闭
     */
    @ReactMethod
    public void isEnableDebug(Promise promise) {
        promise.resolve(XGPushConfig.isEnableDebug(this.reactContext));
    }

    /**
     * 初始化
     * @param accessId
     * @param accessKey
     */
    @ReactMethod
    public void startApp(int accessId, String accessKey) {
        XGPushConfig.setAccessId(this.reactContext, accessId);
        XGPushConfig.setAccessKey(this.reactContext, accessKey);
    }

    /**
     * 注册并绑定帐号
     * @param account 帐号,当为'*'表示解绑
     */
    @ReactMethod
    public void registerPush(String account, final Promise promise) {
        if(account != null && !"".equals(account)) {
            XGPushManager.registerPush(this.reactContext, account, new XGIOperateCallback() {
                @Override
                public void onSuccess(Object date, int flag) {
                    promise.resolve(date);
                }

                @Override
                public void onFail(Object data, int errCode, String msg) {
                    promise.reject(String.valueOf(errCode), msg);
                }
            });
        } else {
            XGPushManager.registerPush(this.reactContext, new XGIOperateCallback() {
                @Override
                public void onSuccess(Object date, int flag) {
                    promise.resolve(date);
                }

                @Override
                public void onFail(Object data, int errCode, String msg) {
                    promise.reject(String.valueOf(errCode), msg);
                }
            });
        }
    }

    /**
     * 反注册
     * @param promise
     */
    @ReactMethod
    public void unregisterPush(final Promise promise) {
        XGPushManager.unregisterPush(this.reactContext, new XGIOperateCallback() {
            @Override
            public void onSuccess(Object data, int flag) {
                WritableMap map = Arguments.createMap();
                map.putString("data", (String) data);
                map.putInt("flag", flag);
                promise.resolve(map);
            }

            @Override
            public void onFail(Object data, int errCode, String msg) {
                promise.reject(String.valueOf(errCode), msg);
            }
        });
    }

    /**
     * 设置tag
     * @param tagName
     */
    @ReactMethod
    public void setTag(String tagName) {
        XGPushManager.setTag(this.reactContext, tagName);
    }

    /**
     * 删除tag
     * @param tagName
     */
    @ReactMethod
    public void deleteTag(String tagName) {
        XGPushManager.deleteTag(this.reactContext, tagName);
    }

    @ReactMethod
    public void addLocalNotification(String title, String content) {
        XGLocalMessage message = new XGLocalMessage();
        message.setTitle(title);
        message.setContent(content);
        Log.i(MODULE_NAME, title);
        Log.i(MODULE_NAME, content);
        XGPushManager.addLocalNotification(this.reactContext, message);
    }

    /**
     * 获取token
     * @return 成功时返回正常的token；失败时返回null或”0”
     */
    @ReactMethod
    public String getToken() {
        return XGPushConfig.getToken(this.reactContext);
    }

    @ReactMethod
    public void setAccessId(String accessId) {
        try{
            XGPushConfig.setAccessId(this.reactContext, Long.parseLong(accessId));
        } catch (NumberFormatException exception) {
            exception.printStackTrace();
        }
    }

    @ReactMethod
    public long getAccessId() {
        return XGPushConfig.getAccessId(this.reactContext);
    }

    @ReactMethod
    public void setAccessKey(String accessKey) {
        XGPushConfig.setAccessKey(this.reactContext, accessKey);
    }

    /**
     * 获取accessKey
     * @return accessKey
     */
    @ReactMethod
    public String getAccessKey() {
        return XGPushConfig.getAccessKey(this.reactContext);
    }

    @ReactMethod
    public void getInitialNotification(Promise promise) {
        WritableMap params = Arguments.createMap();
        Activity activity = getCurrentActivity();
        if (activity != null) {
            Intent intent = activity.getIntent();
            try {
                if(intent != null && intent.hasExtra("protect")) {
                    String title = Rijndael.decrypt(intent.getStringExtra("title"));
                    String content = Rijndael.decrypt(intent.getStringExtra("content"));
                    String customContent = Rijndael.decrypt(intent.getStringExtra("custom_content"));
                    params.putString("title",  title);
                    params.putString("content",  content);
                    params.putString("custom_content",  customContent);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        promise.resolve(params);
    }

    @Override
    public void onHostResume() {
        XGPushManager.onActivityStarted(getCurrentActivity());
    }

    @Override
    public void onHostPause() {
        XGPushManager.onActivityStoped(getCurrentActivity());
    }

    @Override
    public void onHostDestroy() {

    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {

    }

    @Override
    public void onNewIntent(Intent intent) {
        Activity activity = getCurrentActivity();
        if (activity != null) {
            activity.setIntent(intent); // 必须要调用这句
        }
    }
}
