//
//  VinCameraController.h
//  VinDemo
//
//  Created by ocrgroup on 2017/9/28.
//  Copyright © 2017年 ocrgroup. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    kVinPhoneDirectionUp,
    kVinPhoneDirectionUpsideDown,
    kVinPhoneDirectionLeft,
    kVinPhoneDirectionRight,
} VinPhoneDirection;


/* 竖VIN宽高比 */
#define VerticalVINWHRatio 0.2845
/* 横VIN宽高比 */
#define HorizontalVINWHRatio 3.479


@protocol VinCameraDelegate <NSObject>

@required


/**
 识别结果回调

 @param cameraController 相机控制器
 @param vinCode VIN码识别结果
 @param srcImage 完整原图
 @param areaCutImage 区域裁切图
 @param vinImage VIN码图
 */
- (void)cameraController:(UIViewController *)cameraController videoStreamRecognizeFinishWithResult:(NSString *)vinCode srcImage:(UIImage *)srcImage areaCutImage:(UIImage *)areaCutImage andVinImage:(UIImage *)vinImage;

@optional

/**
 点击取消回调方法(内部已pop和dismiss,外部无需做,此接口为混合开发项目提供)
 
 @param cameraController 相机控制器
 */
- (void)backButtonClickWithVinCamera:(UIViewController *)cameraController;

@end

@interface VinCameraController : UIViewController

@property (nonatomic, weak) id <VinCameraDelegate> delegate;

@property (nonatomic, copy) void (^getVinResultFromOCR)(NSDictionary *resultDic);


/**
 识别是否要包含摩托车Vin码
 */
@property (nonatomic, assign) BOOL containMotoVin;
/**
 当前屏幕锁定方向
 */
@property (nonatomic, assign) VinPhoneDirection deviceDirection;

- (instancetype)initWithAuthorizationCode:(NSString *)authorizationCode;

@end
