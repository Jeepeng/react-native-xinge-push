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
import com.facebook.react.bridge.Callback;
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

import me.leolin.shortcutbadger.ShortcutBadger;

/**
 * 信鸽推送
 * Created by Jeepeng on 16/8/3.
 */
public class PushModule extends ReactContextBaseJavaModule implements ActivityEventListener, LifecycleEventListener {

    public static final String MODULE_NAME = "XGPushManager";

    private Context reactContext;
    private int badge = 0;

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
                        String customContent = intent.getStringExtra("custom_content");
                        params.putString("title", title);
                        params.putString("content", content);
                        params.putString("custom_content", customContent);

                        sendEvent(Constants.EVENT_MESSAGE_RECEIVED, params);
                        break;
                    case Constants.ACTION_ON_NOTIFICATION_SHOWED:
                        params.putString("title", intent.getStringExtra("title"));
                        params.putString("content", intent.getStringExtra("content"));
                        params.putString("custom_content", intent.getStringExtra("custom_content"));

                        sendEvent(Constants.EVENT_REMOTE_NOTIFICATION_RECEIVED, params);
                        break;
                    case Constants.ACTION_ON_NOTIFICATION_CLICKED:
                        params.putString("title", intent.getStringExtra("title"));
                        params.putString("content", intent.getStringExtra("content"));
                        params.putString("custom_content", intent.getStringExtra("custom_content"));
                        params.putBoolean("clicked", true);

                        sendEvent(Constants.EVENT_REMOTE_NOTIFICATION_RECEIVED, params);
                        break;
                    default:
                        break;
                }


            }
        }, intentFilter);
    }

    /*****************************************************************
     *                         XGPushManager功能类
     * （对于本类提供的set和enable方法，要在XGPushManager接口前调用才能及时生效）
     *****************************************************************/

    /**
     * 启动并注册APP
     */
    @ReactMethod
    public void registerPush(final Promise promise) {
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

    /**
     * 启动并注册APP，同时绑定账号,推荐有帐号体系的APP使用
     * （此接口会覆盖设备之前绑定过的账号，仅当前注册的账号生效）
     * @param account
     * @param promise
     */
    @ReactMethod
    public void bindAccount(String account, final Promise promise) {
        XGPushManager.bindAccount(this.reactContext, account, new XGIOperateCallback() {
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

    /**
     * 启动并注册APP，同时绑定账号,推荐有帐号体系的APP使用
     * （此接口保留之前的账号，只做增加操作，一个token下最多只能有3个账号超过限制会自动顶掉之前绑定的账号）
     * @param account
     * @param promise
     */
    @ReactMethod
    public void appendAccount(String account, final Promise promise) {
        XGPushManager.appendAccount(this.reactContext, account, new XGIOperateCallback() {
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

    /**
     * 解绑指定账号
     * @param account
     * @param promise
     */
    @ReactMethod
    public void delAccount(String account, final Promise promise) {
        XGPushManager.delAccount(this.reactContext, account, new XGIOperateCallback() {
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
     * 检测通知栏是否关闭
     * @param promise
     */
    @ReactMethod
    public void isNotificationOpened(Promise promise) {
        promise.resolve(XGPushManager.isNotificationOpened(this.reactContext));
    }

    /*****************************************************************
     *                         XGPushConfig配置类
     * （对于本类提供的set和enable方法，要在XGPushManager接口前调用才能及时生效）
     *****************************************************************/

    /**
     * 初始化
     * @param accessId
     * @param accessKey
     */
    @ReactMethod
    public void init(int accessId, String accessKey) {
        XGPushConfig.setAccessId(this.reactContext, accessId);
        XGPushConfig.setAccessKey(this.reactContext, accessKey);
    }

    /**
     * 是否开启debug模式，即输出logcat日志重要：为保证数据的安全性，发布前必须设置为false）
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
     * 获取设备的token，只有注册成功才能获取到正常的结果
     * @param promise
     */
    @ReactMethod
    public void getToken(Promise promise) {
        promise.resolve(XGPushConfig.getToken(this.reactContext));
    }

    /**
     * 设置上报通知栏是否关闭 默认打开
     * @param debugMode
     */
    @ReactMethod
    public void setReportNotificationStatusEnable(boolean debugMode) {
        XGPushConfig.setReportNotificationStatusEnable(this.reactContext, debugMode);
    }

    /**
     * 设置上报APP 列表，用于智能推送 默认打开
     * @param debugMode
     */
    @ReactMethod
    public void setReportApplistEnable(boolean debugMode) {
        XGPushConfig.setReportApplistEnable(this.reactContext, debugMode);
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

    /**
     * 第三方推送开关
     * 需要在 registerPush 之前调用
     */
    @ReactMethod
    public void enableOtherPush(boolean isEnable) {
        XGPushConfig.enableOtherPush(this.reactContext, isEnable);
    }

    @ReactMethod
    public void setHuaweiDebug(boolean isDebug) {
        XGPushConfig.setHuaweiDebug(isDebug);
    }

    @ReactMethod
    public void initXiaomi(String appId, String appKey) {
        XGPushConfig.setMiPushAppId(this.reactContext, appId);
        XGPushConfig.setMiPushAppKey(this.reactContext, appKey);
    }

    @ReactMethod
    public void initMeizu(String appId, String appKey) {
        //设置魅族APPID和APPKEY
        XGPushConfig.setMzPushAppId(this.reactContext, appId);
        XGPushConfig.setMzPushAppKey(this.reactContext, appKey);
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

    @ReactMethod
    public void getApplicationIconBadgeNumber(Callback callback) {
        callback.invoke(this.badge);
    }

    @ReactMethod
    public void setApplicationIconBadgeNumber(int number) {
        this.badge = number;
        ShortcutBadger.applyCount(this.reactContext, number);
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
        /*
        Activity activity = getCurrentActivity();
        if (activity != null) {
            activity.setIntent(intent); // 后台运行时点击通知会调用
        }
        */
    }
}
