package com.etop.utils;

import android.os.Environment;

import java.util.HashMap;

/**
 * 用来配置识别库的一些信息
 */
public class ConstantConfig {
	/**
	 * 授权文件的全名
	 */
	public static final String licenseId = "9C15EEA95B60787AEEEA.lic";
	/**
	 * 核心文件
	 */
	public static final String nc_bin = "nc_vin.bin";
	public static final String nc_dic = "nc_vin.dic";
	public static final String nc_param = "nc_vin.param";

	/**
	 * 授权类型：分为 0x01 绑定手机序列号授权，0x02 绑定应用名和应用包名，0x03 绑定应用包名授权（默认）
	 * <p>
	 * 0x02说明：授权文件绑定的是应用名和应用包名，初始化识别核心会根据授权绑定信息去校验应用名和应用包名
	 * <p>
	 * 0x03说明：授权文件只绑定应用包名，初始化识别核心会根据授权绑定信息只校验应用包名
	 * <p>
	 * 也就是说，你授权文件绑定的应用名和应用包名，就把这个值改为0x02；授权文件只绑定了应用包名，就是默认的 0x03
	 * <p>
	 * 授权类型不对，也是激活失败 ErrorCode：24 的原因之一
	 */
	public static final int nAultType = 0x03;

	/**
	 * 保存图像的路径
	 */
	public static final String saveImgPath = Environment.getExternalStorageDirectory().getPath() + "/alpha/VinCode/";

	/**
	 * 是否保存VIN码灰度缩略图
	 */
	public static final boolean isSaveThume = true;

	/**
	 * 是否保存VIN码框内区域图
	 */
	public static final boolean isSaveArea = true;

	/**
	 * 是否开启导入编辑
	 */
	public static boolean isImportCrop = true;

	/**
	 * 是否增加识别摩托车VIN码
	 * <p>
	 * false: 默认正常识别VIN码
	 * true：在原来默认识别基础上，增加摩托车VIN码也可以识别
	 */
	public static final boolean isCheckMotorbike = false;

	public static String getErrorInfo(int initCode) {
		if (initCode > 19 && initCode < 26) {
			HashMap<Integer, String> errorMap = new HashMap<>();
			errorMap.put(20, "请参考开发文档");
			errorMap.put(21, "未读取到授权文件");
			errorMap.put(22, "授权文件名称不能修改");
			errorMap.put(23, "请参考开发文档");
			errorMap.put(24, "授权信息验证失败");
			errorMap.put(25, "授权已到期");
			return errorMap.get(initCode);
		} else {
			return "";
		}
	}

	/**
	 * 设置识别区域参数
	 * 修改识别区域需要同时修改对应的VinSacnRectView扫描框布局
	 */
	// 竖向参数
	public static double TOP_V_SCALE = 0.37;  // 竖向距离 框顶部距离 缩放比
	public static double BUTTOM_V_SCALE = 0.51; // 竖向距离 底部距离 缩放比
    // 横向参数
	public static double LEFT_H_SCALE = 0.12;  // 横向距离 框左距离 缩放比
	public static double TOP_H_SCALE = 0.4;    // 横向距离 框顶部距离 缩放比
	public static double RIGHT_H_SCALE = 0.82;  // 横向距离 框右面距离 缩放比

}
