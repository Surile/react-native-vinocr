package com.vinocr;

import android.Manifest;
import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import com.etop.activity.ScanVinActivity;
import com.etop.activity.VinRecogActivity;
import com.etop.utils.ConstantConfig;
import com.etop.utils.StreamUtil;
import com.etop.vin.VINAPI;

import java.io.File;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

public class VinocrModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    // 接收识别结果返回码
    private static final int VIN_RECOG_CODE = 101;
    // 进入扫描识别页面权限
    private static final int SCAN_PERMISSION_CODE = 102;
    // 进入导入识别页面权限码
    private static final int IMPORT_PERMISSION_CODE = 103;

    private static Callback callback;

    public VinocrModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @Override
    public String getName() {
        return "Vinocr";
    }

    @ReactMethod
    public void cameraRequest(Callback success){
      callback = success;
      Activity currentActivity = getCurrentActivity();
      if (null != currentActivity) {
        /** 进入识别页面前必须加上，否则识别核心激活失败，返回错误码21，无法识别 **/
        StreamUtil.initLicenseFile(reactContext, ConstantConfig.licenseId);
        StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_bin);
        StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_dic);
        StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_param);
        //Android 6.0以上版本，权限适配
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          //检查是否有相应的权限
          if (ContextCompat.checkSelfPermission(reactContext, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
              && ContextCompat.checkSelfPermission(reactContext, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            // 有权限，启动VIN码扫描识别页面
            Intent intent = new Intent(reactContext, ScanVinActivity.class);
            currentActivity.startActivity(intent);
          } else {
            //没有权限申请权限
            ActivityCompat.requestPermissions(currentActivity, new String[]{Manifest.permission.CAMERA,
                Manifest.permission.WRITE_EXTERNAL_STORAGE}, SCAN_PERMISSION_CODE);
          }
        } else {
          //启动启动VIN码扫描识别页面
          Intent intent = new Intent(reactContext, ScanVinActivity.class);
          currentActivity.startActivity(intent);

        }
      } else{
        Toast.makeText(reactContext, "不能打开", Toast.LENGTH_LONG).show();
      }
    }


	// /**
	//  * 原生导入识别
	//  */
	// @ReactMethod
	// public void importRequest(Callback success) {
	// 	callback = success;
	// 	//启动启动VIN码导入识别页面
	// 	Activity currentActivity = getCurrentActivity();
	// 	if (null != currentActivity) {
	// 		/** 进入识别页面前必须加上，否则识别核心激活失败，返回错误码21，无法识别 **/
	// 		StreamUtil.initLicenseFile(reactContext, ConstantConfig.licenseId);
	// 		StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_bin);
	// 		StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_dic);
	// 		StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_param);
	// 		//Android 6.0以上版本，权限适配
	// 		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
	// 			//检查是否有相应的权限
	// 			if (ContextCompat.checkSelfPermission(reactContext, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
	// 				// 有权限，启动VIN码导入识别页面
	// 				Intent intent = new Intent(reactContext, VinRecogActivity.class);
	// 				currentActivity.startActivity(intent);
	// 			} else {
	// 				//没有权限申请权限
	// 				ActivityCompat.requestPermissions(currentActivity, new String[]{
	// 						Manifest.permission.WRITE_EXTERNAL_STORAGE}, IMPORT_PERMISSION_CODE);
	// 			}
	// 		} else {
	// 			//启动启动VIN码导入识别页面 VinRecogActivity
	// 			Intent intent = new Intent(reactContext, VinRecogActivity.class);
	// 			currentActivity.startActivity(intent);
	// 		}
	// 	} else
	// 		Toast.makeText(reactContext, "不能打开", Toast.LENGTH_LONG).show();
	// }

	/**
	 * RN导入/拍照识别接口
	 */
	private VINAPI vinApi;
	// 返回信息和图片地址
	private String vinResult;
	private String vinThumbPath;
	private int screenWidth;
	private int screenHeight;
	private ProgressDialog progress;
	@ReactMethod
	public void RecogImg(final String picPath, Callback success) {
		/** 进入识别页面前必须加上，否则识别核心激活失败，返回错误码21，无法识别 **/
		StreamUtil.initLicenseFile(reactContext, ConstantConfig.licenseId);
		StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_bin);
		StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_dic);
		StreamUtil.initLicenseFile(reactContext, ConstantConfig.nc_param);
		callback = success;
		Activity currentActivity = getCurrentActivity();
		if (TextUtils.isEmpty(picPath)) {
			Toast.makeText(reactContext, "图片地址为空,无法识别", Toast.LENGTH_LONG).show();
			return;
		}
		if (null != currentActivity) {
			// 调用核心识别
			sendVinApi(currentActivity, picPath);
		} else {
			Toast.makeText(reactContext, "不能打开", Toast.LENGTH_LONG).show();
		}
	}


	/**
	 * 核心识别
	 */
	private void sendVinApi(final Activity currentActivity, final String picPath) {
		//初始化识别核心
		vinApi = VINAPI.getVinInstance();
		int initKernalCode = vinApi.initVinKernal(reactContext);
		if (initKernalCode != 0) {//其他值代表激活失败，具体请参考开发文档
			Toast.makeText(reactContext, "OCR核心激活失败:" + initKernalCode + "\r\n错误信息：" + ConstantConfig.getErrorInfo(initKernalCode), Toast.LENGTH_LONG).show();
		} else {
			//获取授权文件的截止日期
			String endTime = vinApi.VinGetEndTime();
			Log.e("VIN码", "授权截止日期 ------------- " + endTime);
			if (ConstantConfig.isCheckMotorbike) {
				vinApi.VinSetRecogParam(1);
			} else {
				vinApi.VinSetRecogParam(0);
			}
		}
		// 获取宽高
		screenWidth = currentActivity.getWindowManager().getDefaultDisplay().getWidth();
		screenHeight = currentActivity.getWindowManager().getDefaultDisplay().getHeight();
		progress = ProgressDialog.show(currentActivity, "", "正在识别...");
		new Thread(new Runnable() {
			@Override
			public void run() {
				Bitmap bitmap = getSmallBitmap(picPath, screenWidth, screenHeight);
				//识别bitmap图像
				final int nRet = vinApi.VinRecognizeBitmapImage(bitmap);
				if (nRet == 0) {
					//获取识别结果
					vinResult = vinApi.VinGetResult();
					File file = new File(ConstantConfig.saveImgPath);
					if (file.exists() && file.isDirectory() && ConstantConfig.isSaveThume) {
						//生成纯VIN码小图。
						int pLineWarp[] = new int[32000];
						vinApi.VinGetRecogImgData(pLineWarp);
						//这个bitmap就是纯VIN码小图
						Bitmap bitmapThumb = Bitmap.createBitmap(pLineWarp, 400, 80, Bitmap.Config.ARGB_8888);
						vinThumbPath = new StreamUtil().saveBitmapFile(bitmapThumb, ConstantConfig.saveImgPath, "VIN");
					}
				} else {
					vinThumbPath = picPath;
					vinResult = "识别失败,图像中未发现VIN码";
				}
				currentActivity.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						if (progress != null) progress.dismiss();
						// 重置核心
						vinApi.releaseKernal();
						//TODO RN回调
            VinocrModule.dataToJs(vinResult, vinThumbPath);
					}
				});
			}
		}).start();
	}

	/**
	 * 获取压缩图
	 */
	private Bitmap getSmallBitmap(String filePath, int reqWidth, int reqHeight) {
		final BitmapFactory.Options options = new BitmapFactory.Options();
		options.inJustDecodeBounds = true;
		BitmapFactory.decodeFile(filePath, options);

		// Calculate inSampleSize
		options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight);

		// Decode bitmap with inSampleSize set
		options.inJustDecodeBounds = false;
		//避免出现内存溢出的情况，进行相应的属性设置。
		options.inPreferredConfig = Bitmap.Config.ARGB_8888;
		options.inDither = true;

		return BitmapFactory.decodeFile(filePath, options);
	}

	/**
	 * <li> 计算图片的缩放值 </li>
	 *
	 * @param options   options
	 * @param reqWidth  宽
	 * @param reqHeight 高
	 * @return inSampleSize
	 */
	private int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
		final int height = options.outHeight;
		final int width = options.outWidth;
		int inSampleSize = 1;

		if (height > reqHeight || width > reqWidth) {
			final int heightRatio = Math.round((float) height / (float) reqHeight);
			final int widthRatio = Math.round((float) width / (float) reqWidth);
			inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio;
		}
		return inSampleSize;
	}

	/**
	 * 传递数据的回调方法
	 */
	public static void dataToJs(String data, String url) {
		callback.invoke(data, url);
	}
}
