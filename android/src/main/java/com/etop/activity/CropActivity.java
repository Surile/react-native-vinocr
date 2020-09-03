package com.etop.activity;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.etop.utils.ConstantConfig;
import com.etop.utils.StreamUtil;
import com.etop.view.TouchImageView;
import com.vinocr.R;

public class CropActivity extends Activity implements View.OnClickListener {

	// 缩放旋转绘图
	private TouchImageView mImageView;
	// 提示布局
	private RelativeLayout vin_crop_tip_layout;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_crop);
		// 初始化view
		initView();
	}

	/**
	 * 初始化view
	 */
	private void initView() {
		//  获取导入图
		int screenWidth = getWindowManager().getDefaultDisplay().getWidth();
		int screenHeight = getWindowManager().getDefaultDisplay().getHeight();
		Bitmap mBitmap = getSmallBitmap(getIntent().getStringExtra("imgpath"), screenWidth, screenHeight);
		RelativeLayout mCrViewLayout = (RelativeLayout) findViewById(R.id.vin_crop_image);
//		FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(screenWidth, screenHeight);
//		mCrViewLayout.setLayoutParams(params);
		//设置图片显示宽高为屏幕宽度
		FrameLayout.LayoutParams params1 = new FrameLayout.LayoutParams(screenWidth, screenHeight);
		mImageView = new TouchImageView(this, mBitmap);
		mCrViewLayout.addView(mImageView, params1);

		ImageButton save = findViewById(R.id.cri_crop_save);
		TextView vin_crop_left = findViewById(R.id.vin_crop_left);
		TextView vin_crop_right = findViewById(R.id.vin_crop_right);
		TextView vin_crop_tip_tv = findViewById(R.id.vin_crop_tip_tv);
		RelativeLayout vin_ration_layout = findViewById(R.id.vin_crop_ration_layout);
		ImageButton vin_title_ib_left = findViewById(R.id.vin_crop_title_ib_left);
		ImageButton vin_crop_cancletip = findViewById(R.id.vin_crop_cancletip);
		vin_crop_tip_layout = findViewById(R.id.vin_crop_tip_layout);

		save.setOnClickListener(this);
		vin_crop_left.setOnClickListener(this);
		vin_crop_right.setOnClickListener(this);
		vin_title_ib_left.setOnClickListener(this);
		vin_crop_cancletip.setOnClickListener(this);

		// 设置提示语位置
		RelativeLayout.LayoutParams lpTv = (RelativeLayout.LayoutParams) vin_crop_tip_tv.getLayoutParams();
		lpTv.topMargin = (int) (screenHeight * 0.51);
		vin_crop_tip_tv.setLayoutParams(lpTv);
		vin_crop_tip_tv.setRotation(0);
		// 设置旋转按钮位置
		RelativeLayout.LayoutParams lpRation = (RelativeLayout.LayoutParams) vin_ration_layout.getLayoutParams();
		lpRation.topMargin = (int) (screenHeight * 0.51);
		vin_ration_layout.setLayoutParams(lpRation);
		// 设置操作提示位置
		FrameLayout.LayoutParams lpFinger = (FrameLayout.LayoutParams) vin_crop_tip_layout.getLayoutParams();
		lpFinger.topMargin = (int) (screenHeight * 0.1);
		vin_crop_tip_layout.setLayoutParams(lpFinger);
	}

	/**
	 * 监听
	 *
	 * @param v
	 */
	@Override
	public void onClick(View v) {
		int i = v.getId();
		if (i == R.id.cri_crop_save) {  // 保存
			String vinAreaPath = new StreamUtil().saveBitmapFile(mImageView.CreatNewPhoto(), ConstantConfig.saveImgPath, "VIN_C");
			Intent intent = new Intent();
			intent.putExtra("imgpath", vinAreaPath);
			CropActivity.this.setResult(RESULT_OK, intent);
			CropActivity.this.finish();
		} else if (i == R.id.vin_crop_left) { // 旋转
			mImageView.drawRotation(-90);
		} else if (i == R.id.vin_crop_right) { // 旋转
			mImageView.drawRotation(90);
		} else if (i == R.id.vin_crop_title_ib_left) { // 返回X
			finish();
		} else if (i == R.id.vin_crop_cancletip) { // 取消提示
			vin_crop_tip_layout.setVisibility(View.GONE);
		}
	}

	/**
	 * 获取压缩图
	 */
	public Bitmap getSmallBitmap(String filePath, int reqWidth, int reqHeight) {
		final BitmapFactory.Options options = new BitmapFactory.Options();
		options.inJustDecodeBounds = true;
		BitmapFactory.decodeFile(filePath, options);

		// Calculate inSampleSize
		options.inSampleSize = StreamUtil.computeSize(reqWidth, reqHeight);

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
	public int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
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


}
