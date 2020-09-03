package com.etop.view;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import androidx.annotation.Nullable;
import android.util.AttributeSet;
import android.view.View;

import com.vinocr.R;


public class VinScanRectView extends View {
	private Paint paintCorner;
	private Paint paintLine;
	private Rect rectTop;
	private Rect rectBottom;
	private Rect rectLeft;
	private Rect rectRight;
	private int marTop;
	private Paint paintCorner2;
	private int lineWidth;
	private int lineLength;
	private int bottomHeight;
	private boolean isVerticalScreen = true;

	public VinScanRectView(Context context) {
		this(context, null);
	}

	public VinScanRectView(Context context, @Nullable AttributeSet attrs) {
		this(context, attrs, -1);
	}

	public VinScanRectView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
		super(context, attrs, defStyleAttr);

		marTop = (int) getResources().getDimension(R.dimen.camera_top_margin);
		lineLength = (int) getResources().getDimension(R.dimen.camera_rect_line_length);
		lineWidth = (int) getResources().getDimension(R.dimen.camera_rect_lint_width);
		paintLine = new Paint(Paint.ANTI_ALIAS_FLAG);
		paintLine.setColor(Color.parseColor("#59D4D1"));
		paintLine.setStyle(Paint.Style.STROKE);//设置空心
		paintLine.setStrokeWidth(lineWidth);
		paintCorner = new Paint(Paint.ANTI_ALIAS_FLAG);
		paintCorner.setColor(Color.parseColor("#66000000"));

		paintCorner2 = new Paint(Paint.ANTI_ALIAS_FLAG);
		paintCorner2.setColor(Color.parseColor("#99000000"));
	}

	@Override
	protected void onDraw(Canvas canvas) {
		super.onDraw(canvas);
		int width = getWidth();
		int height = getHeight();
		int left, top, right, bottom;
		// 设置横竖扫描框的位置
		if (isVerticalScreen) {
			left = 3;
			top = (int) (height * 0.36);
			right = width - 3;
			bottom = (int) (height * 0.51);
		} else {
			left = (int) (width * 0.37);
			top = (int) (height * 0.11);
			right = width - left;
			bottom = (int) (height * 0.83);
		}
		//绘制四个半透明矩形
		rectTop = new Rect(0, marTop, width, top);
		canvas.drawRect(rectTop, paintCorner);
		rectBottom = new Rect(0, bottom, width, height);
		canvas.drawRect(rectBottom, paintCorner);
		rectLeft = new Rect(0, top, left, bottom);
		canvas.drawRect(rectLeft, paintCorner);
		rectRight = new Rect(right, top, width, bottom);
		canvas.drawRect(rectRight, paintCorner);

		bottomHeight = height - bottom;

		//left + top
		canvas.drawLine(left, top, left + lineLength, top, paintLine);
		canvas.drawLine(left, top, left, top + lineLength, paintLine);

		//right + top
		canvas.drawLine(right, top, right - lineLength, top, paintLine);
		canvas.drawLine(right, top, right, top + lineLength, paintLine);

		//left + bottom
		canvas.drawLine(left, bottom, left + lineLength, bottom, paintLine);
		canvas.drawLine(left, bottom, left, bottom - lineLength, paintLine);

		//right + bottom
		canvas.drawLine(right, bottom, right - lineLength, bottom, paintLine);
		canvas.drawLine(right, bottom, right, bottom - lineLength, paintLine);
	}

	/**
	 * 设置是否是竖屏模式
	 *
	 * @param isVertical
	 */
	public void setIsVertical(boolean isVertical) {
		isVerticalScreen = isVertical;
		invalidate();
	}

	public int getBottomHeight() {
		return bottomHeight;
	}
}
