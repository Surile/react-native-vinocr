//
//  VinManager.m
//  VinDemo
//
//  Created by ocrgroup on 2018/3/9.
//  Copyright © 2018年 ocrgroup. All rights reserved.
//

#import "VinManager.h"
#import "vinTyper.h"

@interface VinManager () <VinCameraDelegate>

@property (nonatomic, strong) VinTyper * vinTyper;

@end


@implementation VinManager

static id _instacetype;

#pragma mark - 单例创建
+ (instancetype)sharedVinManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"BundleID:%@",[[NSBundle mainBundle] bundleIdentifier]);
        _instacetype = [[super alloc] init];
    });
    return _instacetype;
}

#pragma mark - 功能函数实现
//MARK:视频流预览识别
- (void)recognizeVinCodeByVideoStreamWithController:(UIViewController *)parentController usePush:(BOOL)usePush andAuthCode:(NSString *)authCode {
    NSLog(@"SDK版本号：%@", self.sdkVersion);
    VinCameraController * cameraVC = [[VinCameraController alloc] initWithAuthorizationCode:authCode];
    cameraVC.delegate = self;
    cameraVC.containMotoVin = self.containMotoVin;
    cameraVC.deviceDirection = cameraVC.preferredInterfaceOrientationForPresentation - 1;
    if (usePush) {
        [parentController.navigationController pushViewController:cameraVC animated:YES];
    } else {
        cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [parentController presentViewController:cameraVC animated:YES completion:nil];
    }
    
}

//MARK:视频流代理回调
- (void)cameraController:(UIViewController *)cameraController videoStreamRecognizeFinishWithResult:(NSString *)vinCode srcImage:(UIImage *)srcImage areaCutImage:(UIImage *)areaCutImage andVinImage:(UIImage *)vinImage {
    if ([self.delegate respondsToSelector:@selector(cameraController:videoStreamRecognizeVinFinishWithResult:srcImage:areaCutImage:andVinImage:)]) {
        [self.delegate cameraController:cameraController videoStreamRecognizeVinFinishWithResult:vinCode srcImage:srcImage areaCutImage:areaCutImage andVinImage:vinImage];
    } else {
        NSLog(@"代理方法cameraController:videoStreamRecognizeVinFinishWithResult:srcImage:areaCutImage:andVinImage:未实现");
    }
}


//MARK:导入/拍照识别
- (void)recognizeVinCodeWithPhoto:(UIImage *)vinImage andAuthCode:(NSString *)authCode {
    NSLog(@"SDK版本号：%@", self.sdkVersion);
    int success = [self initRecognizeCoreWithAuthCode:authCode];
    if (success != 0) {
        //激活失败
        if ([self.delegate respondsToSelector:@selector(photoRecognizeFinishWithResult:srcImage:vinImage:andErrorCode:)]) {
            [self.delegate photoRecognizeFinishWithResult:nil srcImage:vinImage vinImage:nil andErrorCode:success];
        } else {
            NSLog(@"代理方法photoRecognizeFinishWithResult:andErrorCode:未实现");
        }
        return ;
    }
    
    vinImage = [self fixOrientation:vinImage];
    
    int bSuccess = [self.vinTyper recognizeVinTyperImage:vinImage];
    
    if ([self.delegate respondsToSelector:@selector(photoRecognizeFinishWithResult:srcImage:vinImage:andErrorCode:)]) {
        [self.delegate photoRecognizeFinishWithResult:self.vinTyper.nsResult srcImage:vinImage vinImage:self.vinTyper.resultImg andErrorCode:bSuccess];
    } else {
        NSLog(@"代理方法photoRecognizeFinishWithResult:andErrorCode:未实现");
    }
    
    [self.vinTyper freeVinTyper];
    
}

//MARK:图片方向修复
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

//MARK:初始化识别核心
- (int)initRecognizeCoreWithAuthCode:(NSString *)authCode {
    int nRet = [self.vinTyper initVinTyper:authCode nsReserve:@""];
    if (nRet != 0) {
        NSString *initStr = [NSString stringWithFormat:@"Init Error!Error code:%d",nRet];
        if (nRet == 22) {
            initStr = [initStr stringByAppendingString:@"(Can't find lic)"];
        } else if (nRet == 24) {
            initStr = [initStr stringByAppendingString:@"(BundleID error)"];
        } else if (nRet == 25) {
            initStr = [initStr stringByAppendingString:@"(Out of date)"];
        } else if (nRet == 20) {
            initStr = [initStr stringByAppendingString:@"(Product is not supported)"];
        } else if (nRet == 21) {
            initStr = [initStr stringByAppendingString:@"(Do not use simulator)"];
        } else if (nRet == 6) {
            initStr = [initStr stringByAppendingString:@"(Duplicated init)"];
        } else if (nRet == 49) {
            initStr = [initStr stringByAppendingString:@"(Can't find nc* file)"];
        } else if (nRet == 10) {
            initStr = [initStr stringByAppendingString:@"(copy nc* file failed)"];
        }
        UIAlertView *alertV = [[UIAlertView alloc] initWithTitle:@"Tips" message:initStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertV show];
        
    } else {
        //成功
        int day = [self calculateTheRemainingDaysOfLicenceWithDeadLine:self.vinTyper.nsEndTime];
        
        if (day <= 15 && day != -1) {
            NSLog(@"⚠️授权还有不到15天到期❗️❗️❗️请及时更换");
        }
        //若需要识别摩托车Vin，需要加上这句代码来去掉一些校验规则以识别摩托车Vin
        if (self.containMotoVin) {
            [self.vinTyper setVinVerifyType:1];
        }
        
    }
    return nRet;
}

- (int)calculateTheRemainingDaysOfLicenceWithDeadLine:(NSString *)deadLine {
    if (!deadLine) {
        NSLog(@"deadline is nil");
        return -1;
    }
    //按照日期格式创建日期格式句柄
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    [dateFormatter setTimeZone:localTimeZone];
    //将日期字符串转换成Date类型
    
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [dateFormatter dateFromString:deadLine];
    //将日期转换成时间戳
    NSTimeInterval start = [startDate timeIntervalSince1970]*1;
    NSTimeInterval end = [endDate timeIntervalSince1970]*1;
    NSTimeInterval value = end - start;
    int day = (int)value / (24 * 3600);
    return day+1;
}

//MARK:核心
- (VinTyper *)vinTyper {
    if (!_vinTyper) {
        _vinTyper = [[VinTyper alloc] init];
    }
    return _vinTyper;
}

- (NSString *)sdkVersion {
    return self.vinTyper.sdkVersion;
}

- (NSString *)codeVersion {
    return @"V2020.06.12";
}

@end
