package com.etop.utils;

import android.content.Context;
import android.widget.Toast;

public class ToastUtil {
    public static Toast mToast;
    public static void show(Context context , String text){
        if (mToast == null){
            mToast = Toast.makeText( context, text , Toast.LENGTH_SHORT);
        }else {
            //如果当前Toast没有消失， 直接显示内容，不需要重新设置
            mToast.setText(text);
        }
        mToast.show();
    }
    public static void cancelToast() {
        if (mToast != null) {
            mToast.cancel();
            mToast=null;
        }
    }
}
