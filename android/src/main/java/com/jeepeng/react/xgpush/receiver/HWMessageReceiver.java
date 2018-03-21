package com.jeepeng.react.xgpush.receiver;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;

import com.huawei.hms.support.api.push.PushReceiver;
import com.jeepeng.react.xgpush.Constants;

import java.io.FileWriter;
import java.io.IOException;

/**
 * 华为官方推送通道消息接收器
 * Created by Jeepeng on 2018/3/11.
 */

public class HWMessageReceiver extends PushReceiver {

    @Override
    public void onEvent(Context context, Event event, Bundle extras) {
        if (Event.NOTIFICATION_OPENED.equals(event) || Event.NOTIFICATION_CLICK_BTN.equals(event)) {
            int notifyId = extras.getInt(BOUND_KEY.pushNotifyId, 0);
            if (0 != notifyId) {
                NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                manager.cancel(notifyId);
            }
        }

        String message = extras.getString(BOUND_KEY.pushMsgKey);
        String deviceToken = extras.getString(BOUND_KEY.deviceTokenKey);
        int receiveType = extras.getInt(BOUND_KEY.receiveTypeKey);
        String pushState = extras.getString(BOUND_KEY.pushStateKey);
        int pushNotifyId = extras.getInt(BOUND_KEY.pushNotifyId, 0);
        // message:[{"id":"123456"}]
        // Bundle[{receiveType=4, pushMsg=[{"id":"1"},{"name":"jeepeng"},{"sex":"man"}]}]

        if (Event.NOTIFICATION_OPENED.equals(event)) {
            // 通知在通知栏被点击啦。。。。。
            Intent intent = new Intent(Constants.ACTION_ON_NOTIFICATION_CLICKED);
            Bundle bundle = new Bundle();
            bundle.putString("content", message);
            intent.putExtra("notification", bundle);

            intent.putExtra("content", message);
            intent.putExtra("custom_content", message);
            context.sendBroadcast(intent);
        }

        super.onEvent(context, event, extras);
    }

    @Override
    public boolean onPushMsg(Context context, byte[] msg, Bundle bundle) {
        try {
            String content = new String(msg, "UTF-8");
            Intent intent = new Intent(Constants.ACTION_ON_TEXT_MESSAGE);
            intent.putExtra("content", content);
            context.sendBroadcast(intent);
            System.out.println(bundle);
            Log.i("HWMessageReceiver", "收到PUSH透传消息,消息内容为:" + content);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return super.onPushMsg(context, msg, bundle);
    }

    @Override
    public void onPushState(Context context, boolean pushState) {
        super.onPushState(context, pushState);
    }

    @Override
    public void onToken(Context context, String token, Bundle extras) {
        super.onToken(context, token, extras);
    }

    @Override
    public void onToken(Context context, String token) {
        super.onToken(context, token);
    }

    private void  writeToFile(String conrent) {
        String SDPATH = Environment.getExternalStorageDirectory() + "/huawei.txt";
        try {
            FileWriter fileWriter = new FileWriter(SDPATH, true);

            fileWriter.write(conrent+"\r\n");
            fileWriter.flush();
            fileWriter.close();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }


}