//
//  VinManager.h
//  VinDemo
//
//  Created by ocrgroup on 2018/3/9.
//  Copyright © 2018年 ocrgroup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VinCameraController.h"


@protocol VinManagerDelegate <NSObject>


/**
 导入/拍照识别回调
 
 @param vinCode 识别结果
 @param srcImage 传入识别的VIN码图片
 @param vinImage VIN码图片(截取)
 @param errorCode 错误码
 */
- (void)photoRecognizeFinishWithResult:(NSString *)vinCode srcImage:(UIImage *)srcImage vinImage:(UIImage *)vinImage andErrorCode:(int)errorCode;


/**
 视频流识别回调
 
 @param cameraController 自定义相机控制器
 @param vinCode 识别结果
 @param srcImage 完整原图
 @param areaCutImage 区域裁切图
 @param vinImage VIN码图
 */
- (void)cameraController:(UIViewController *)cameraController videoStreamRecognizeVinFinishWithResult:(NSString *)vinCode srcImage:(UIImage *)srcImage areaCutImage:(UIImage *)areaCutImage andVinImage:(UIImage *)vinImage;

@end

@interface VinManager : NSObject

/**
 回调代理
 */
@property (nonatomic, weak) id <VinManagerDelegate> delegate;

/**
 识别是否要包含摩托车Vin码
 */
@property (nonatomic, assign) BOOL containMotoVin;

/**
 SDK版本号
 */
@property (nonatomic, copy) NSString * sdkVersion;

/**
 Demo版本号
 */
@property (nonatomic, copy) NSString * codeVersion;


/**
 单例全局访问点
 
 @return 对象实例
 */
+ (instancetype)sharedVinManager;

/**
 拍照/导入识别
 
 @param vinImage 需要识别的图像
 @param authCode 授权文件名
 */
- (void)recognizeVinCodeWithPhoto:(UIImage *)vinImage andAuthCode:(NSString *)authCode;


/**
 视频流预览识别
 
 @param parentController 当前控制器(self)
 @param usePush 是否使用push弹出控制器 [YES-push NO-modal(模态弹出)]
 @param authCode 授权文件名
 */
- (void)recognizeVinCodeByVideoStreamWithController:(UIViewController *)parentController usePush:(BOOL)usePush andAuthCode:(NSString *)authCode;


@end
