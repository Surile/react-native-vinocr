package com.etop.activity;

import android.app.Activity;
import android.app.Service;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.etop.camera.CommonCameraView;

import com.etop.utils.ConstantConfig;
import com.etop.utils.DetectStateUtil;
import com.etop.utils.StreamUtil;
import com.etop.utils.NV21ToARGBUtil;
import com.etop.utils.ToastUtil;
import com.etop.view.VinScanRectView;
import com.etop.vin.VINAPI;
import com.vinocr.R;
import com.vinocr.VinocrModule;


import java.io.File;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

/**
 * 视频流识别vin
 */
public class ScanVinActivity extends Activity implements CommonCameraView.PreviewFrameListener, View.OnClickListener {

	private int screenHeight;
	private int screenWidth;
	private CommonCameraView mCameraView;
	private ImageButton mTitleIbBack;
	private TextView mTitleTvHead;
	private ImageButton mTitleIbChange;
	private boolean isVertical = true;
	private boolean isOpenFlash = false;
	private TranslateAnimation horizontalAnimation;
	private TranslateAnimation verticalAnimation;
	private VinScanRectView mRectview;
	private ImageView mIvvScanLine;
	private ImageView mIvhScanLine;
	private LinearLayout mLlFlashLight;
	private ImageView mIvFlashLight;
	private TextView mTvCue;
	private FrameLayout mFrameLayout;
	private VINAPI vinApi;
	private int orientation;
	public int preWidth = 0;
	public int preHeight = 0;
	private int[] borders;
	private RelativeLayout mRootLayout;
	private boolean isRecogVin = true;

	private DetectStateUtil detectStateUtil; //环境监测

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_scan_vin);

		mFrameLayout = (FrameLayout) findViewById(R.id.aevs_vin_frame_layout);
		mRootLayout = (RelativeLayout) findViewById(R.id.etop_vin_root_layout);
		mTitleIbBack = (ImageButton) findViewById(R.id.etop_title_ib_left);
		mTitleTvHead = (TextView) findViewById(R.id.etop_title_tv_head);
		mTitleIbChange = (ImageButton) findViewById(R.id.etop_title_ib_right);
		mRectview = (VinScanRectView) findViewById(R.id.aevs_vsrv_rectview);

		mIvvScanLine = (ImageView) findViewById(R.id.aevs_ivv_scanline);
		mIvhScanLine = (ImageView) findViewById(R.id.aevs_ivh_scanline);
		mLlFlashLight = (LinearLayout) findViewById(R.id.aevs_ll_flashlight);
		mIvFlashLight = (ImageView) findViewById(R.id.aevs_iv_flashlight);
		mTvCue = (TextView) findViewById(R.id.aevs_tv_cue);
		// 声明一个DisplayMetrics对象
		DisplayMetrics metrics = new DisplayMetrics();
		// 获取Manager对象后获取Display对象，然后调用getMetrics()方法
		getWindowManager().getDefaultDisplay().getMetrics(metrics);
		// 从DisplayMetrics对象中获取宽、高
		screenHeight = metrics.heightPixels;
		screenWidth = metrics.widthPixels;

		mTitleTvHead.setText("车架号VIN码识别");
		mCameraView = new CommonCameraView(this, screenWidth, screenHeight, CommonCameraView.LOW);
		mFrameLayout.addView(mCameraView);

		initVerticalView();

		//创建保存图像的文件夹
		File file = new File(ConstantConfig.saveImgPath);
		if (!file.exists() || !file.isDirectory()) {
			file.mkdirs();
		}

		mTitleIbBack.setOnClickListener(this);
		mTitleIbChange.setOnClickListener(this);
		mLlFlashLight.setOnClickListener(this);

		mCameraView.setOnCameraSizeListener(new CommonCameraView.CameraSizeListener() {
			@Override
			public void setCameraSize(int[] size) {
				if (size != null) {
					preWidth = size[0];
					preHeight = size[1];
					setIsVerticalRecog(true);
					mCameraView.setOnPreviewFrameListener(ScanVinActivity.this);
					//拿到适配的相机预览比例
					double previewScale = preHeight / (double) preWidth;
					//拿到真实的屏幕比例
					double screenScale = screenWidth / (double) screenHeight;
					//预览的和实际显示的差距较大
					if (Math.abs(previewScale - screenScale) > 0) {
						//说明屏幕长，适配的预览比例大（比如三星S系列）
						if (previewScale > screenScale) {
							ViewGroup.LayoutParams layoutParams = mRootLayout.getLayoutParams();
							int height = (int) (screenWidth / previewScale);
							layoutParams.height = height;
							mRootLayout.setLayoutParams(layoutParams);
							screenHeight = height;
						}
					}
				} else {
					Toast.makeText(ScanVinActivity.this, "请开启相机权限", Toast.LENGTH_SHORT).show();
				}
			}
		});
		detectStateUtil = new DetectStateUtil();
	}

	@Override
	protected void onStart() {
		super.onStart();
		isRecogVin = true;
		vinApi = VINAPI.getVinInstance();
		//获取初始化核心的错误码：解决方案详见开发文档
		int initKernalCode = vinApi.initVinKernal(this);
		if (initKernalCode == 0) {
			if (ConstantConfig.isCheckMotorbike) {
				vinApi.VinSetRecogParam(1);
			} else {
				vinApi.VinSetRecogParam(0);
			}
		} else {
			mTvCue.setText("OCR核心激活失败，ErrorCode:" + initKernalCode + "\r\n错误信息：" + ConstantConfig.getErrorInfo(initKernalCode));
		}
	}

	/**
	 * 监听
	 *
	 * @param view
	 */
	public void onClick(View view) {
		int mId = view.getId();
		if (mId == R.id.etop_title_ib_left) {
			finish();
		} else if (mId == R.id.etop_title_ib_right) {//切换横竖屏，识别模式
			if (isVertical) {
				//已为竖向，变横向
				initHorizontalView();
				setIsVerticalRecog(false);
				isVertical = false;
			} else {
				//已为横向，变竖向
				initVerticalView();
				setIsVerticalRecog(true);
				isVertical = true;
			}

		} else if (mId == R.id.aevs_ll_flashlight) {//手电筒
			isOpenFlash = !isOpenFlash;
			boolean isSupport = mCameraView.alterFlash(isOpenFlash ? 3 : 2);
			if (isSupport) {
				mIvFlashLight.setBackgroundResource(isOpenFlash ? R.mipmap.vin_flash_light_on : R.mipmap.vin_flash_light);
			} else {
				ToastUtil.show(this, "当前设备不支持闪光灯");
			}

		}
	}

	/**
	 * 检线初始化
	 */
	private ThreadPoolExecutor recogTPE = new ThreadPoolExecutor(1, 1, 1,
			TimeUnit.MILLISECONDS, new LinkedBlockingQueue<Runnable>());
	private int buffl = 30;
	private char recogval[] = new char[buffl];
	private int pLineWarp[] = new int[32000];

	@Override
	public void setPreviewFrame(final byte[] data) {
		if (isRecogVin) {
			isRecogVin = false;
			recogTPE.execute(new Runnable() {
								 @Override
								 public void run() {
									 synchronized (this) {
										 processFrame(data);
									 }
								 }
							 }
			);
		}
	}

	private void processFrame(byte[] frameData) {
		// 判断光强度设置曝光
		int exposure = detectStateUtil.detectExposureLight(frameData, preWidth, preHeight);
		// 根据亮度设置曝光级别
		if (exposure == 1 || exposure == 0 || exposure == -1) {
			mCameraView.setExposureCompensationLevel(exposure);
		}
		int recogCode = vinApi.VinRecognizeNV21Android(frameData, preWidth, preHeight, recogval, buffl, pLineWarp, orientation);
		Log.e("recogCode", recogCode + "");
		if (recogCode == 0) {
			isRecogVin = false;
			Vibrator mVibrator = (Vibrator) getSystemService(Service.VIBRATOR_SERVICE);
			mVibrator.vibrate(100);
			final String recogResult = vinApi.VinGetResult();
			Log.e("recogResult", recogResult);
			String vinThumbPath = "";
			String vinAreaPath = "";


			File file = new File(ConstantConfig.saveImgPath);
			if (ConstantConfig.isSaveThume && file.exists() && file.isDirectory()) {
				//生成灰度的小缩略图（只有VIN码）
				Bitmap bitmapThumb = Bitmap.createBitmap(pLineWarp, 400, 80, Bitmap.Config.RGB_565);
				vinThumbPath = new StreamUtil().saveBitmapFile(bitmapThumb, ConstantConfig.saveImgPath, "VIN");
				bitmapThumb.recycle();
			}
			if (ConstantConfig.isSaveArea && file.exists() && file.isDirectory()) {
				int[] argb8888 = new NV21ToARGBUtil().convertYUV420_NV21toARGB8888(frameData, preWidth, preHeight);
				Bitmap bitmap = Bitmap.createBitmap(argb8888, preWidth, preHeight, Bitmap.Config.RGB_565);
				if (orientation == 0) {
					Bitmap bitmapRegion = Bitmap.createBitmap(bitmap, borders[0], borders[1], borders[2] - borders[0], borders[3] - borders[1]);
					bitmap.recycle();
					vinAreaPath = new StreamUtil().saveBitmapFile(bitmapRegion, ConstantConfig.saveImgPath, "VIN_Y");
				} else {
					Bitmap bitmapRegion = Bitmap.createBitmap(bitmap, borders[1], borders[0], borders[3] - borders[1], borders[2] - borders[0]);
					bitmap.recycle();
					vinAreaPath = new StreamUtil().saveBitmapFile2(bitmapRegion, ConstantConfig.saveImgPath, "VIN_Y");
				}
			}

			Intent intent = new Intent();
			intent.putExtra("vinResult", recogResult);
			intent.putExtra("recogCode", recogCode + "");
			if (ConstantConfig.isSaveThume)
				intent.putExtra("vinThumbPath", vinThumbPath);
			if (ConstantConfig.isSaveArea)
				intent.putExtra("vinAreaPath", vinAreaPath);
      //TODO RN回调
      VinocrModule.dataToJs(recogResult, vinThumbPath);
      setResult(RESULT_OK, intent);
      finish();
		} else {
			isRecogVin = true;
		}
	}

	/**
	 * 设置识别区域
	 */
	public void setIsVerticalRecog(boolean isVerticalRecog) {
		int t, b, l, r;
		if (isVerticalRecog) {
			orientation = 1;
			//设置竖向识别区域
			t = (int) (preWidth * ConstantConfig.TOP_V_SCALE);
			b = (int) (preWidth * ConstantConfig.BUTTOM_V_SCALE);
			l = 0;
			r = preHeight;
			borders = new int[]{l, t, r, b};
			vinApi.VinSetROI(borders, preWidth, preHeight);
		} else {
			orientation = 0;
			//设置横向识别区域
			l = (int) (preWidth * ConstantConfig.LEFT_H_SCALE);
			r = (int) (preWidth * ConstantConfig.RIGHT_H_SCALE);
			t = (int) (preHeight * ConstantConfig.TOP_H_SCALE);
			b = preHeight - t;
			borders = new int[]{l, t, r, b};
			vinApi.VinSetROI(borders, preWidth, preHeight);
		}
	}

	/**
	 * 初始化横向布局
	 */
	private void initHorizontalView() {
		RelativeLayout.LayoutParams lpll = (RelativeLayout.LayoutParams) mLlFlashLight.getLayoutParams();
		lpll.topMargin = (int) (screenHeight * 0.83);
		mLlFlashLight.setLayoutParams(lpll);

		RelativeLayout.LayoutParams lpTv = (RelativeLayout.LayoutParams) mTvCue.getLayoutParams();
		lpTv.topMargin = (int) (screenHeight * 0.435);
		mTvCue.setLayoutParams(lpTv);
		mTvCue.setRotation(90);
		RelativeLayout.LayoutParams lphScan = (RelativeLayout.LayoutParams) mIvhScanLine.getLayoutParams();
		lphScan.topMargin = (int) (screenHeight * 0.45);
		mIvhScanLine.setLayoutParams(lphScan);

		if (verticalAnimation != null) {//如果已开启垂直动画，则，关闭，隐藏控件
			verticalAnimation.cancel();
			mIvvScanLine.clearAnimation();
			mIvvScanLine.invalidate();
			mIvvScanLine.setVisibility(View.GONE);
		}

		// y轴移动距离
		horizontalAnimation = new TranslateAnimation( // y轴移动距离
				Animation.RELATIVE_TO_PARENT, -0.125f, Animation.RELATIVE_TO_PARENT, 0.125f,
				Animation.RELATIVE_TO_PARENT, 0, Animation.RELATIVE_TO_PARENT, 0);
		horizontalAnimation.setDuration(950); // 动画持续时间
		horizontalAnimation.setRepeatMode(Animation.REVERSE);//反转位移
		horizontalAnimation.setRepeatCount(Animation.INFINITE); // 无限循环
		//播放动画
		mIvhScanLine.startAnimation(horizontalAnimation);
		mIvhScanLine.setVisibility(View.VISIBLE);//显示动画

		mRectview.setIsVertical(false);

	}

	/**
	 * 初始化竖向布局
	 */
	private void initVerticalView() {
		RelativeLayout.LayoutParams lpll = (RelativeLayout.LayoutParams) mLlFlashLight.getLayoutParams();
		lpll.topMargin = (int) (screenHeight * 0.52);
		mLlFlashLight.setLayoutParams(lpll);

		RelativeLayout.LayoutParams lpTv = (RelativeLayout.LayoutParams) mTvCue.getLayoutParams();
		lpTv.topMargin = (int) (screenHeight * 0.41);
		mTvCue.setLayoutParams(lpTv);
		mTvCue.setRotation(0);
		mRectview.setIsVertical(true);
		RelativeLayout.LayoutParams lpScan = (RelativeLayout.LayoutParams) mIvvScanLine.getLayoutParams();
		lpScan.topMargin = (int) (screenHeight * 0.417);
		mIvvScanLine.setLayoutParams(lpScan);

		if (horizontalAnimation != null) {//如果已开启垂直动画，则，关闭，隐藏控件
			horizontalAnimation.cancel();
			mIvhScanLine.clearAnimation();
			mIvhScanLine.invalidate();
			mIvhScanLine.setVisibility(View.GONE);
		}
		// y轴移动距离
		verticalAnimation = new TranslateAnimation( // y轴移动距离
				Animation.RELATIVE_TO_PARENT, 0, Animation.RELATIVE_TO_PARENT, 0f,
				Animation.RELATIVE_TO_PARENT, -0.07f, Animation.RELATIVE_TO_PARENT, 0.07f);
		verticalAnimation.setDuration(1000); // 动画持续时间
		verticalAnimation.setRepeatMode(Animation.REVERSE);//反转位移
		verticalAnimation.setRepeatCount(Animation.INFINITE); // 无限循环
		//播放动画
		mIvvScanLine.startAnimation(verticalAnimation);
		mIvvScanLine.setVisibility(View.VISIBLE);//显示动画

	}


}
