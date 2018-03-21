package com.jeepeng.react.xgpush.receiver;

import android.content.Context;

import com.meizu.cloud.pushsdk.MzPushMessageReceiver;
import com.meizu.cloud.pushsdk.platform.message.PushSwitchStatus;
import com.meizu.cloud.pushsdk.platform.message.RegisterStatus;
import com.meizu.cloud.pushsdk.platform.message.SubAliasStatus;
import com.meizu.cloud.pushsdk.platform.message.SubTagsStatus;
import com.meizu.cloud.pushsdk.platform.message.UnRegisterStatus;

/**
 * 魅族官方推送通道消息接收器
 * Created by Jeepeng on 2018/3/12.
 */

public class MZMessageReceiver extends MzPushMessageReceiver {
    @Override
    public void onRegister(Context context, String s) {

    }

    @Override
    public void onMessage(Context context, String s) {

    }

    @Override
    public void onUnRegister(Context context, boolean b) {

    }

    @Override
    public void onPushStatus(Context context, PushSwitchStatus pushSwitchStatus) {

    }

    @Override
    public void onRegisterStatus(Context context, RegisterStatus registerStatus) {

    }

    @Override
    public void onUnRegisterStatus(Context context, UnRegisterStatus unRegisterStatus) {

    }

    @Override
    public void onSubTagsStatus(Context context, SubTagsStatus subTagsStatus) {

    }

    @Override
    public void onSubAliasStatus(Context context, SubAliasStatus subAliasStatus) {

    }
}
