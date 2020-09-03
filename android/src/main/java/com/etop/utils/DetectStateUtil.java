package com.etop.utils;

import android.util.Log;

/**
 * Created by ZhangHui on 2019/7/17.
 * Describe: 检测证件状态的工具类
 */
public class DetectStateUtil {

	//上次记录的时间戳
	long lastRecordTime = System.currentTimeMillis();
	//上次记录的索引
	int darkIndex = 0;
	//一个历史记录的数组，255是代表亮度最大值
	long[] darkList = new long[]{255, 255, 255, 255};
	//扫描间隔
	int waitScanTime = 300;

	//亮度低的阀值
	int darkValue = 60;

	private int count = 0;

	/**
	 * 检测前环境太暗(曝光使用)
	 *
	 * @param data
	 * @param preWidth
	 * @param preHeight
	 */
	public int detectExposureLight(byte[] data, int preWidth, int preHeight) {
		//像素点的总亮度
		long pixelLightCount = 0L;
		//像素点的总数
		long pixeCount = preWidth * preHeight;
		//采集步长，因为没有必要每个像素点都采集，可以跨一段采集一个，减少计算负担，必须大于等于1。
		int step = 10;
		//data.length - allCount * 1.5f的目的是判断图像格式是不是YUV420格式，只有是这种格式才相等
		//因为int整形与float浮点直接比较会出问题，所以这么比
		if (Math.abs(data.length - pixeCount * 1.5f) < 0.00001f) {
			for (int i = 0; i < pixeCount; i += step) {
				//如果直接加是不行的，因为data[i]记录的是色值并不是数值，byte的范围是+127到—128，
				// 而亮度FFFFFF是11111111是-127，所以这里需要先转为无符号unsigned long参考Byte.toUnsignedLong()
				pixelLightCount += ((long) data[i]) & 0xffL;
			}
			//平均亮度
			long cameraLight = pixelLightCount / (pixeCount / step);
			//更新历史记录
//            int lightSize = darkList.length;
//            darkList[darkIndex = darkIndex % lightSize] = cameraLight;
//            darkIndex++;
//            boolean isDarkEnv = false;
//            //判断在时间范围waitScanTime * lightSize内是不是亮度过暗
//            for (int i = 0; i < lightSize; i++) {
//                if (darkList[i] > darkValue) {
//                    isDarkEnv = true;
//                }
//            }
			Log.e("MainActivity", "摄像头环境亮度为 ： " + cameraLight);
			if (cameraLight < 50) { // 进行正曝光设置
				count++;
				if (count > 5) { // 当前亮度持续次数
					return 3;
				}
			} else if (cameraLight > 50 && cameraLight < 110) {  // 不进行曝光设置(保持当前曝光度)
				return -200;
			} else if (cameraLight > 110) { // 大于数值进行  负曝光
				return -1;
			} else {
				count = 0;
				return 0;
			}
		}
		return 0;
	}

	/**
	 * 检测证件当前环境太暗
	 *
	 * @param data
	 * @param preWidth
	 * @param preHeight
	 */
	public boolean detectLight(byte[] data, int preWidth, int preHeight) {
		//像素点的总亮度
		long pixelLightCount = 0L;
		//像素点的总数
		long pixeCount = preWidth * preHeight;
		//采集步长，因为没有必要每个像素点都采集，可以跨一段采集一个，减少计算负担，必须大于等于1。
		int step = 10;
		//data.length - allCount * 1.5f的目的是判断图像格式是不是YUV420格式，只有是这种格式才相等
		//因为int整形与float浮点直接比较会出问题，所以这么比
		if (Math.abs(data.length - pixeCount * 1.5f) < 0.00001f) {
			for (int i = 0; i < pixeCount; i += step) {
				//如果直接加是不行的，因为data[i]记录的是色值并不是数值，byte的范围是+127到—128，
				// 而亮度FFFFFF是11111111是-127，所以这里需要先转为无符号unsigned long参考Byte.toUnsignedLong()
				pixelLightCount += ((long) data[i]) & 0xffL;
			}
			//平均亮度
			long cameraLight = pixelLightCount / (pixeCount / step);
			//更新历史记录
//            int lightSize = darkList.length;
//            darkList[darkIndex = darkIndex % lightSize] = cameraLight;
//            darkIndex++;
//            boolean isDarkEnv = false;
//            //判断在时间范围waitScanTime * lightSize内是不是亮度过暗
//            for (int i = 0; i < lightSize; i++) {
//                if (darkList[i] > darkValue) {
//                    isDarkEnv = true;
//                }
//            }
			Log.e("MainActivity", "摄像头环境亮度为 ： " + cameraLight);
			if (cameraLight < 50) { // 亮度阈值
				count++;
				if (count > 20) { // 当前亮度持续次数
					return true;
				}
			} else {
				count = 0;
			}
		}
		return false;
	}


	//是否距离过远
//    private boolean isDistanceFar = false;

	/**
	 * 检测证件太远
	 */
//    public boolean detectFar(int preWidth, int preHeight, int[] mLineX, int[] mLineY) {
//        int xZhouJuLi1 = mLineX[1] - mLineX[0];
//        int xZhouJuLi2 = mLineX[2] - mLineX[3];
//        int yZhouJuLi1 = mLineY[2] - mLineY[1];
//        int yZhouJuLi2 = mLineY[3] - mLineY[0];
//        //先判断证件方向是横向还是竖向（以手机竖向为准）
//        //如果x方向距离大于y方向距离说明是证件竖向
//        if (xZhouJuLi1 > yZhouJuLi1 && xZhouJuLi1 > yZhouJuLi2 && xZhouJuLi2 > yZhouJuLi1) {
//            if ((xZhouJuLi1 + xZhouJuLi2) < preWidth && (yZhouJuLi1 + yZhouJuLi2) < preHeight) {
//                //证件距离过远
//                isDistanceFar = true;
//            } else {
//                isDistanceFar = false;
//            }
//        } else if (xZhouJuLi1 < yZhouJuLi1 && xZhouJuLi1 < yZhouJuLi2 && xZhouJuLi2 < yZhouJuLi2) {
//            //否则，证件横向
//            float scale = (yZhouJuLi1 + yZhouJuLi2) / (float) preHeight;
//            if (scale < 1.6) {
//                //证件距离过远
//                isDistanceFar = true;
//            } else {
//                isDistanceFar = false;
//            }
//        }
//        return isDistanceFar;
//    }

	//是否倾斜角度过大
//    private boolean isTiltAngle = false;

	/**
	 * 检测倾斜角度过大
	 *
	 * @param preWidth
	 * @param preHeight
	 * @param mLineX
	 * @param mLineY
	 */
//    public boolean detectTiltAngle(int preWidth, int preHeight, int[] mLineX, int[] mLineY) {
//        int xZhouJuLi1 = mLineX[1] - mLineX[0];
//        int xZhouJuLi2 = mLineX[2] - mLineX[3];
//        int yZhouJuLi1 = mLineY[2] - mLineY[1];
//        int yZhouJuLi2 = mLineY[3] - mLineY[0];
//
//        //先判断证件方向是横向还是竖向（以手机竖向为准）
//        //如果x方向距离大于y方向距离说明是证件竖向
//        if (xZhouJuLi1 > yZhouJuLi1 && xZhouJuLi1 > yZhouJuLi2 && xZhouJuLi2 > yZhouJuLi1) {
//            int targerValue = preWidth / 10;
//            if (Math.abs(xZhouJuLi1 - xZhouJuLi2) > targerValue) {
//                //倾斜角度过大
//                isTiltAngle = true;
//            } else {
//                isTiltAngle = false;
//            }
//        } else if (xZhouJuLi1 < yZhouJuLi1 && xZhouJuLi1 < yZhouJuLi2 && xZhouJuLi2 < yZhouJuLi2) {
//            //否则，证件横向
//            int targerValue = preHeight / 10;
//            if (Math.abs(yZhouJuLi1 - yZhouJuLi2) > targerValue) {
//                //倾斜角度过大
//                isTiltAngle = true;
//            } else {
//                isTiltAngle = false;
//            }
//        }
//        return isTiltAngle;
//    }

	//是否旋转角度过大
//    private boolean isRotateAngle = false;

	/**
	 * 检测旋转角度过大
	 *
	 * @param preWidth
	 * @param preHeight
	 * @param mLineX
	 * @param mLineY
	 */
//    public boolean detectRotateAngle(int preWidth, int preHeight, int[] mLineX, int[] mLineY) {
//        int xZhouJuLi1 = Math.abs(mLineX[2] - mLineX[0]);
//        int xZhouJuLi2 = Math.abs(mLineX[3] - mLineX[1]);
//        int yZhouJuLi1 = Math.abs(mLineY[3] - mLineY[1]);
//        int yZhouJuLi2 = Math.abs(mLineY[2] - mLineY[0]);
//        int targerValue = preHeight / 3;
//        int targerValue2 = preHeight / 6;
//        if (xZhouJuLi1 > 0 && yZhouJuLi1 > 0) {
//            if (xZhouJuLi1 < targerValue2 || xZhouJuLi2 < targerValue || yZhouJuLi1 < targerValue
//                    || yZhouJuLi2 < targerValue2) {
//                //旋转角度过大
//                isRotateAngle = true;
//            } else {
//                isRotateAngle = false;
//            }
//        }
//        return isRotateAngle;
//    }

	private int detectCount1 = 0;
	private int detectCount2 = 0;
	private int detectCount3 = 0;
	private int DETECT_VALUE = 1;

	public int detectCardState(int preWidth, int preHeight, int[] mLineX, int[] mLineY) {
		int xZhouJuLi1 = mLineX[1] - mLineX[0];
		int xZhouJuLi2 = mLineX[2] - mLineX[3];
		int yZhouJuLi1 = mLineY[2] - mLineY[1];
		int yZhouJuLi2 = mLineY[3] - mLineY[0];
		int xZhouJuLi3 = Math.abs(mLineX[2] - mLineX[0]);
		int yZhouJuLi3 = Math.abs(mLineY[3] - mLineY[1]);
		int xZhouJuLi4 = Math.abs(mLineX[3] - mLineX[1]);
		int yZhouJuLi4 = Math.abs(mLineY[2] - mLineY[0]);

		if (xZhouJuLi3 > 0 && yZhouJuLi3 > 0) {
			int targerValue = preHeight / 3;
			int targerValue2 = preHeight / 6;
			if (xZhouJuLi3 < targerValue2 || xZhouJuLi4 < targerValue || yZhouJuLi3 < targerValue
					|| yZhouJuLi4 < targerValue2) {
				//旋转角度过大
				detectCount3++;
				if (detectCount3 == DETECT_VALUE) {
					detectCount3 = 0;
					return 3;
				}
			} else {
				detectCount3 = 0;
			}
		}

		//先判断证件方向是横向还是竖向（以手机竖向为准）
		//如果x方向距离大于y方向距离说明是证件竖向
		if (xZhouJuLi1 > yZhouJuLi1 && xZhouJuLi1 > yZhouJuLi2 && xZhouJuLi2 > yZhouJuLi1) {
			if ((xZhouJuLi1 + xZhouJuLi2) < preWidth && (yZhouJuLi1 + yZhouJuLi2) < preHeight) {
				//证件距离过远
				detectCount1++;
				if (detectCount1 == DETECT_VALUE) {
					detectCount1 = 0;
					return 1;
				}
			} else {
				detectCount1 = 0;
			}
//            int abs = Math.abs(xZhouJuLi1 - xZhouJuLi2);
//            int iiiii = preHeight / 4;
//            Log.e("abs:"+abs,"iiiii:"+iiiii);
			if (Math.abs(xZhouJuLi1 - xZhouJuLi2) > preHeight / 4) {
//            if (abs > iiiii) {
				//倾斜角度过大
				detectCount2++;
				if (detectCount2 == DETECT_VALUE) {
					detectCount2 = 0;

					return 2;
				}
			} else {
				detectCount2 = 0;
			}
		} else if (xZhouJuLi1 < yZhouJuLi1 && xZhouJuLi1 < yZhouJuLi2 && xZhouJuLi2 < yZhouJuLi2) {
			//否则，证件横向
			float scale = (yZhouJuLi1 + yZhouJuLi2) / (float) preHeight;
			if (scale < 1.6) {
				//证件距离过远
				detectCount1++;
				if (detectCount1 == DETECT_VALUE) {
					detectCount1 = 0;
					return 1;
				}
			} else {
				detectCount1 = 0;
			}
			if (Math.abs(yZhouJuLi1 - yZhouJuLi2) > preHeight / 6) {
				//倾斜角度过大
				detectCount2++;
				if (detectCount2 == DETECT_VALUE) {
					detectCount2 = 0;
					Log.e("111111111", "xxxxxxxxx");
					return 2;
				}
			} else {
				detectCount2 = 0;
			}
		}
		return 0;
	}
}
