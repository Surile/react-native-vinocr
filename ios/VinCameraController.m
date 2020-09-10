//
//  VinCameraController.m
//  VinDemo
//
//  Created by ocrgroup on 2017/9/28.
//  Copyright © 2017年 ocrgroup. All rights reserved.
//

#import "VinCameraController.h"
#import <AVFoundation/AVFoundation.h>
#import "VinSquareView.h"
#import "vinTyper.h"
#import "VinVerticalButton.h"


//iPhone X顶部状态栏安全区
#define SafeAreaStatusBarHeight (isIPhoneXSeries() ? 24 : 0)

#define THEMECOLOR [UIColor colorWithRed:89/255.0 green:212/255.0 blue:209/255.0 alpha:1]


#define SCREENH [UIScreen mainScreen].bounds.size.height
#define SCREENW [UIScreen mainScreen].bounds.size.width

static inline BOOL isIPhoneXSeries() {
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    return iPhoneXSeries;
}


@interface VinCameraController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIView * statusBar;


@property (nonatomic, strong) UIButton * backButton;

@property (nonatomic, strong) VinSquareView * squareView;

@property (nonatomic, strong) VinVerticalButton * torchButton;

@property (nonatomic, assign) BOOL isHorizontalRecognize;

@property (nonatomic, strong) UILabel * centerTipLabel;

@property (nonatomic, strong) VinTyper * vinTyper;


@property (nonatomic, strong) UIButton * hvSwitchButton;

@property (nonatomic, strong) UILabel * titleLabel;


@property (nonatomic, strong) UIView * navBar;


//相机相关
@property (nonatomic, strong) AVCaptureSession * captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput * captureInput;
@property (nonatomic, strong) AVCaptureStillImageOutput * captureOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput * captureVideoOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * capturePreviewLayer;
@property (nonatomic, strong) AVCaptureDevice * captureDevice;

@property (nonatomic, assign) BOOL isFocusing;//是否正在对焦
@property (nonatomic, assign) BOOL isFocusPixels;//是否相位对焦

@property (nonatomic, assign) GLfloat focusPixelsPosition;//相位对焦下镜头位置

@property (nonatomic, assign) GLfloat curPosition;//当前镜头位置

@property (nonatomic, strong) UIImageView * scanLine;

@property (nonatomic, copy) NSString * authorizationCode;

@property (nonatomic, assign) BOOL needFreeKernal;//是否需要释放核心

@end

@implementation VinCameraController
- (instancetype)initWithAuthorizationCode:(NSString *)authorizationCode {
    if (self = [super init]) {
        self.authorizationCode = authorizationCode;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    [self prepareUI];
    //初始化相机
    [self initCameraAndLayer];
    
    //此处修改默认横屏还是竖屏
    self.isHorizontalRecognize = NO;
    if (self.isHorizontalRecognize) {
        self.hvSwitchButton.selected = YES;
    } else {
        self.hvSwitchButton.selected = NO;
    }
    
    
    [self initRecognizeCore];
    if (self.isHorizontalRecognize) {
        [self.vinTyper setVinRecognizeType:0];
    } else {
        [self.vinTyper setVinRecognizeType:1];
    }
    [self setVinDetectArea];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.captureSession.inputs.count > 0 && self.captureSession.outputs.count > 0) {
        [self.captureSession startRunning];
    }
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [self moveScanline];
    
    //判断是否相位对焦
    AVCaptureDeviceFormat *deviceFormat = self.captureDevice.activeFormat;
    if (deviceFormat.autoFocusSystem == AVCaptureAutoFocusSystemPhaseDetection) {
        self.isFocusPixels = YES;
    }
    
    //注册通知
    [self.captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    if (self.isFocusPixels) {
        [self.captureDevice addObserver:self forKeyPath:@"lensPosition" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    //监听切换到前台事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveScanline) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    if (self.isFocusPixels) {
        [self.captureDevice removeObserver:self forKeyPath:@"lensPosition"];
    }
    self.torchButton.selected = NO;
    //移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    NSLog(@"stopRunning");
    [self.captureSession stopRunning];
//    NSLog(@"freeKernal");
    //释放核心
//    [self.vinTyper freeVinTyper];
    
    self.needFreeKernal = YES;
    
    
}

- (void)initRecognizeCore {
    //初始化识别核心
    int nRet = [self.vinTyper initVinTyper:self.authorizationCode nsReserve:@""];
    if (nRet != 0) {
        [self.captureSession stopRunning];
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
        int day = [VinCameraController calculateTheRemainingDaysOfLicenceWithDeadLine:self.vinTyper.nsEndTime];
        
        if (day <= 15 && day != -1) {
            NSLog(@"⚠️授权还有不到15天到期❗️❗️❗️请及时更换");
        }
        //若需要识别摩托车Vin，需要调用此配置方法去掉一些校验规则以识别摩托车Vin
        if (self.containMotoVin) {
            [self.vinTyper setVinVerifyType:1];
        }
        
    }
    
}

+ (int)calculateTheRemainingDaysOfLicenceWithDeadLine:(NSString *)deadLine {
    if (!deadLine || [deadLine isEqualToString:@""]) {
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



- (void)initCameraAndLayer {
    //判断摄像头是否授权
    AVAuthorizationStatus authorStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorStatus == AVAuthorizationStatusRestricted || authorStatus == AVAuthorizationStatusDenied) {
        
        UIAlertView * alt = [[UIAlertView alloc] initWithTitle:@"未获得授权使用摄像头" message:@"请在 '设置-隐私-相机' 中打开" delegate:self cancelButtonTitle:nil otherButtonTitles:@"知道了", nil];
        [alt show];
        
        return;
    }
    
    //输入设备
    if ([self.captureSession canAddInput:self.captureInput]) {
        [self.captureSession addInput:self.captureInput];
    } else {
        NSLog(@"Can not add input");
        return ;
    }
    
    //输出设备
    if ([self.captureSession canAddOutput:self.captureOutput]) {
        [self.captureSession addOutput:self.captureOutput];
    } else {
        NSLog(@"Can not add AVCaptureStillImageOutput");
        return ;
    }
    
    if ([self.captureSession canAddOutput:self.captureVideoOutput]) {
        [self.captureSession addOutput:self.captureVideoOutput];
    } else {
        NSLog(@"Can not add AVCaptureVideoDataOutput");
        return ;
    }
    
    //添加预览层
    [self.view.layer insertSublayer:self.capturePreviewLayer atIndex:0];
    
}

- (void)prepareUI {
    self.titleLabel.text = @"请扫描VIN码";
    
    [self.view addSubview:self.statusBar];
    
    [self.view addSubview:self.navBar];
    //布局需要用到这两个控件的值 所以把他们放这里
    self.statusBar.frame = CGRectMake(0, 0, SCREENW, 20 + SafeAreaStatusBarHeight);
    
    self.navBar.frame = CGRectMake(0, CGRectGetHeight(self.statusBar.frame), SCREENW, 44);
    
    [self.navBar addSubview:self.titleLabel];
    
    [self.navBar addSubview:self.backButton];
    
    [self.navBar addSubview:self.hvSwitchButton];
    
    [self.view addSubview:self.squareView];
    
    [self.view addSubview:self.scanLine];
    
    [self.view addSubview:self.torchButton];
    
    if (!self.captureDevice.hasTorch) {
        self.torchButton.hidden = YES;
    }
    
    [self.view addSubview:self.centerTipLabel];
    
    
    [self frameSetup];
}

- (void)frameSetup {
    
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(SCREENW * 0.5, CGRectGetHeight(self.navBar.frame) * 0.5);
    
    self.backButton.frame = CGRectMake(0, 0, 40, CGRectGetHeight(self.navBar.frame));
    self.backButton.center = CGPointMake(25, CGRectGetHeight(self.navBar.frame) * 0.5);
    
    
    self.hvSwitchButton.frame = CGRectMake(0, 0, 40, CGRectGetHeight(self.navBar.frame));
    self.hvSwitchButton.center = CGPointMake(SCREENW - 25, CGRectGetHeight(self.navBar.frame) * 0.5);
    
    
    self.torchButton.frame = CGRectMake(0, 0, 60, 40);
    self.torchButton.center = CGPointMake(SCREENW * 0.5, CGRectGetMaxY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame) + 20);
    
    self.centerTipLabel.frame = CGRectMake(0, 0, 135, 25);
    self.centerTipLabel.center = CGPointMake(SCREENW * 0.5, CGRectGetMidY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame));
    
    self.centerTipLabel.layer.cornerRadius = 25 * 0.5;
    self.centerTipLabel.layer.masksToBounds = YES;
    if (self.isHorizontalRecognize) {
        self.centerTipLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.centerTipLabel.transform = CGAffineTransformIdentity;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 点击事件

- (void)backButtonClick {
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)hvSwitchButtonClick {
    self.hvSwitchButton.selected = !self.hvSwitchButton.selected;
    if (self.hvSwitchButton.isSelected) {
        self.isHorizontalRecognize = YES;
    } else {
        self.isHorizontalRecognize = NO;
    }
    
}

- (UIImage *)cutVinAreaWithImage:(UIImage *)fullImage {
    CGRect rcVin = CGRectZero;
    
    CGFloat x = self.squareView.squareRect.origin.x;
    CGFloat y = self.squareView.squareRect.origin.y;
    CGFloat width = self.squareView.squareRect.size.width;
    CGFloat height = self.squareView.squareRect.size.height;
    
    //    CGFloat sessionWidth = 1080;
    //    CGFloat sessionHeight = 1920;
    
    CGFloat controlWidth = CGRectGetWidth(self.squareView.frame);
    CGFloat controlHeight = CGRectGetHeight(self.squareView.frame);
    
    UIImage *rotateImage = fullImage;
    
    CGFloat sessionWidth = rotateImage.size.width;
    CGFloat sessionHeight = rotateImage.size.height;
    
    
    if (self.isHorizontalRecognize) {
        x = self.squareView.squareRect.origin.y;
        y = self.squareView.squareRect.origin.x;
        width = self.squareView.squareRect.size.height;
        height = self.squareView.squareRect.size.width;
        
        CGFloat temp = controlWidth;
        controlWidth = controlHeight;
        controlHeight = temp;
    }
    
    CGFloat ratio = 1;
    if (sessionWidth / sessionHeight > controlWidth / controlHeight) {
        ratio = sessionHeight / controlHeight;
    } else {
        ratio = sessionWidth / controlWidth;
    }
    
    rcVin = CGRectMake(x * ratio, y * ratio, width * ratio, height * ratio);
    
    
    if (sessionWidth / sessionHeight > controlWidth / controlHeight) {
        CGFloat offset = (sessionWidth - sessionHeight / controlHeight * controlWidth) * 0.5;
        rcVin.origin.x += ABS(offset);
    } else {
        CGFloat offset = (sessionHeight - sessionWidth / controlWidth * controlHeight) * 0.5;
        rcVin.origin.y += ABS(offset);
    }
    
    
    CGImageRef imageRef = rotateImage.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, rcVin);
    UIGraphicsBeginImageContext(rcVin.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, rcVin, subImageRef);
    UIImage *vinImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    CGImageRelease(subImageRef);
    
    
    return vinImage;
    
}

- (void)torchButtonClick {
    
    self.torchButton.selected = !self.torchButton.selected;
    if (!self.captureDevice.hasTorch) {
        //NSLog(@"no torch");
    } else {
        [self.captureDevice lockForConfiguration:nil];
        if (self.torchButton.isSelected) {
            [self.captureDevice setTorchMode: AVCaptureTorchModeOn];
        } else {
            [self.captureDevice setTorchMode: AVCaptureTorchModeOff];
        }
        [self.captureDevice unlockForConfiguration];
    }
}


#pragma mark - AVCaptureSession delegate
//从缓冲区获取图像数据进行识别
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.isFocusing) {
        return ;
    }
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    
    if (self.curPosition == self.focusPixelsPosition) {
        //开始识别
        int bSuccess = [self.vinTyper recognizeVinTyper:baseAddress Width:(int)width Height:(int)height];
        
        //        NSLog(@"bSuccess:%d",bSuccess);
        //识别成功
        if (bSuccess == 0) {
            //震动
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            UIImage *srcImage = [VinCameraController imageFromSampleBuffer:sampleBuffer];
            
            NSLog(@"%@",self.vinTyper.nsResult);
            [self.captureSession stopRunning];
            dispatch_async(dispatch_get_main_queue(), ^{
                //传递识别结果
                [self deliverResultAndImage:srcImage];
            });
            
        }
        if (self.needFreeKernal) {
            [self.vinTyper freeVinTyper];
        }
    } else {
        self.curPosition = self.focusPixelsPosition;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
}

- (void)deliverResultAndImage:(UIImage *)srcImage {
    if (!self.isHorizontalRecognize) {
        srcImage = [VinCameraController rotateImage:srcImage rotation:UIImageOrientationRight];
    }
    //裁切vin码区域
    UIImage * vinImage = [self cutVinAreaWithImage:srcImage];
    
    
    if ([self.delegate respondsToSelector:@selector(cameraController:videoStreamRecognizeFinishWithResult:srcImage:areaCutImage:andVinImage:)]) {
        [self.delegate cameraController:self videoStreamRecognizeFinishWithResult:self.vinTyper.nsResult srcImage:srcImage areaCutImage:vinImage andVinImage:self.vinTyper.resultImg];
    } else {
        NSLog(@"%s [Line %d]%@:cameraController:videoStreamRecognizeFinishWithResult:srcImage:areaCutImage:andVinImage: was unimplemented", __PRETTY_FUNCTION__, __LINE__, self.delegate);
    }
    
}

#pragma mark - 监听对焦
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"adjustingFocus"]) {
        self.isFocusing = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
    }
    if ([keyPath isEqualToString:@"lensPosition"]) {
        self.focusPixelsPosition = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
    }
}


//移动扫描线
- (void)moveScanline {
    CGPoint startCenterPoint = CGPointZero;
    if (self.isHorizontalRecognize) {
        startCenterPoint = CGPointMake(CGRectGetMaxX(self.squareView.squareRect), CGRectGetMidY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame));
    } else {
        startCenterPoint = CGPointMake(CGRectGetMidX(self.squareView.squareRect), CGRectGetMinY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame));
    }
    self.scanLine.center = startCenterPoint;
    if (self.isHorizontalRecognize) {
        [UIView animateWithDuration:2.5f delay:0.0f options:UIViewAnimationOptionRepeat animations:^{
            CGPoint center = startCenterPoint;
            center.x -= self.squareView.squareRect.size.width;
            self.scanLine.center = center;
        } completion:^(BOOL finished) {
        }];
    } else {
        [UIView animateWithDuration:2.5f delay:0.0f options:UIViewAnimationOptionRepeat animations:^{
            CGPoint center = startCenterPoint;
            center.y += self.squareView.squareRect.size.height;
            self.scanLine.center = center;
        } completion:^(BOOL finished) {
        }];
    }
    
}

#pragma mark - 工具方法
+ (UIImage *)rotateImage:(UIImage *)image rotation:(UIImageOrientation)orientation {
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newPic;
}


+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    // Get a CMSampleBuffer‘s Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0f orientation:UIImageOrientationUp];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    return (image);
}


#pragma mark - Setter
- (void)setIsHorizontalRecognize:(BOOL)isHorizontalRecognize {
    _isHorizontalRecognize = isHorizontalRecognize;
    if (isHorizontalRecognize) {
        self.centerTipLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
        [self.vinTyper setVinRecognizeType:0];
    } else {
        self.centerTipLabel.transform = CGAffineTransformIdentity;
        [self.vinTyper setVinRecognizeType:1];
    }
    [self.squareView removeFromSuperview];
    self.squareView = nil;
    [self.view insertSubview:self.squareView belowSubview:self.torchButton];
    
    [self.scanLine removeFromSuperview];
    self.scanLine = nil;
    [self.view insertSubview:self.scanLine aboveSubview:self.squareView];
    [self moveScanline];
    
    
    self.torchButton.center = CGPointMake(SCREENW * 0.5, CGRectGetMaxY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame) + 40);
    
    
    [self setVinDetectArea];
}


- (void)setVinDetectArea {
    CGFloat x,y,h,w;
    int left,top,right,bottom;
    
    CGFloat sessionWidth = 1080;
    CGFloat sessionHeight = 1920;
    //    CGFloat sessionWidth = 720;
    //    CGFloat sessionHeight = 1280;
    
    CGFloat controlWidth = CGRectGetWidth(self.squareView.frame);
    CGFloat controlHeight = CGRectGetHeight(self.squareView.frame);
    
    if (self.isHorizontalRecognize) {
        x = self.squareView.squareRect.origin.y;
        y = self.squareView.squareRect.origin.x;
        h = self.squareView.squareRect.size.width;
        w = self.squareView.squareRect.size.height;
        
        
        CGFloat temp = sessionWidth;
        sessionWidth = sessionHeight;
        sessionHeight = temp;
        
        temp = controlWidth;
        controlWidth = controlHeight;
        controlHeight = temp;
        
    } else {
        x = self.squareView.squareRect.origin.x;
        y = self.squareView.squareRect.origin.y;
        h = self.squareView.squareRect.size.height;
        w = self.squareView.squareRect.size.width;
        
    }
    
    CGFloat ratio = 1;
    if (sessionWidth / sessionHeight > controlWidth / controlHeight) {
        ratio = sessionHeight / controlHeight;
    } else {
        ratio = sessionWidth / controlWidth;
    }
    
    //计算参数
    left = x * ratio;
    top = y * ratio;
    right = (x + w) * ratio;
    bottom = (y + h) * ratio;
    
    
    
    if (sessionWidth / sessionHeight > controlWidth / controlHeight) {
        CGFloat offset = (sessionWidth - sessionHeight / controlHeight * controlWidth) * 0.5;
        left += ABS(offset);
        right += ABS(offset);
    } else {
        CGFloat offset = (sessionHeight - sessionWidth / controlWidth * controlHeight) * 0.5;
        top += ABS(offset);
        bottom += ABS(offset);
    }
    
    NSLog(@"left%d top%d right%d bottom%d", left, top, right, bottom);
    [self.vinTyper setVinRegionWithLeft:left Top:top Right:right Bottom:bottom];
}


#pragma mark - lazy load

#pragma mark 相机相关
- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        [_captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
        //AVCaptureSessionPreset1280x720
    }
    return _captureSession;
}

- (AVCaptureDeviceInput *)captureInput {
    if (!_captureInput) {
        _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    }
    return _captureInput;
    
}

- (AVCaptureStillImageOutput *)captureOutput {
    if (!_captureOutput) {
        //创建、配置输出
        _captureOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
        [_captureOutput setOutputSettings:outputSettings];
    }
    return _captureOutput;
}

- (AVCaptureVideoPreviewLayer *)capturePreviewLayer {
    if (!_capturePreviewLayer) {
        _capturePreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        _capturePreviewLayer.frame = CGRectMake(0, CGRectGetMaxY(self.navBar.frame), SCREENW, SCREENH - CGRectGetMaxY(self.navBar.frame));
        _capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _capturePreviewLayer;
}

- (AVCaptureDevice *)captureDevice {
    if (!_captureDevice) {
        NSArray *deviceArr = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in deviceArr) {
            if (device.position == AVCaptureDevicePositionBack) {
                _captureDevice = device;
                _captureInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            }
        }
    }
    return _captureDevice;
}

- (AVCaptureVideoDataOutput *)captureVideoOutput {
    if (!_captureVideoOutput) {
        _captureVideoOutput = [[AVCaptureVideoDataOutput alloc] init];
        _captureVideoOutput.alwaysDiscardsLateVideoFrames = YES;
        dispatch_queue_t queue;
        queue = dispatch_queue_create("cameraQueue", NULL);
        [_captureVideoOutput setSampleBufferDelegate:self queue:queue];
        NSString * formatKey = (NSString *)kCVPixelBufferPixelFormatTypeKey;
        NSNumber * value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
        NSDictionary * videoSettings = [NSDictionary dictionaryWithObject:value forKey:formatKey];
        [_captureVideoOutput setVideoSettings:videoSettings];
    }
    return _captureVideoOutput;
}

#pragma mark kernal

- (VinTyper *)vinTyper {
    if (!_vinTyper) {
        _vinTyper = [[VinTyper alloc] init];
    }
    return _vinTyper;
}

#pragma mark UI

- (UIView *)statusBar {
    if (!_statusBar) {
        _statusBar = [[UIView alloc] init];
        _statusBar.backgroundColor = [UIColor blackColor];
    }
    return _statusBar;
}

- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] init];
        _navBar.backgroundColor = [UIColor blackColor];
    }
    return _navBar;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"拍摄";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    return _titleLabel;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage * backImage = [UIImage imageNamed:@"VinImageResource.bundle/fanhui"];
        [_backButton setImage:backImage forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [[_backButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        _backButton.contentEdgeInsets = UIEdgeInsetsMake(14, 0, 14, 0);
    }
    return _backButton;
}

- (UIButton *)hvSwitchButton {
    if (!_hvSwitchButton) {
        _hvSwitchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage * hengImage = [UIImage imageNamed:@"VinImageResource.bundle/hengping"];
        UIImage * shuImage = [UIImage imageNamed:@"VinImageResource.bundle/shuping"];
        [_hvSwitchButton setImage:hengImage forState:UIControlStateNormal];
        [_hvSwitchButton setImage:shuImage forState:UIControlStateSelected];
        [_hvSwitchButton addTarget:self action:@selector(hvSwitchButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [[_hvSwitchButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        _hvSwitchButton.contentEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    }
    return _hvSwitchButton;
}

- (VinSquareView *)squareView {
    if (!_squareView) {
        if (!self.isHorizontalRecognize) {
            _squareView = [[VinSquareView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), SCREENW, SCREENH - CGRectGetMaxY(self.navBar.frame)) margin:0 bottomHeight:CGRectGetHeight(self.navBar.frame) andSquareRatio:HorizontalVINWHRatio];
        } else {
            _squareView = [[VinSquareView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), SCREENW, SCREENH - CGRectGetMaxY(self.navBar.frame)) margin:35 bottomHeight:49 andSquareRatio:VerticalVINWHRatio];
        }
        
    }
    return _squareView;
}

- (VinVerticalButton *)torchButton {
    if (!_torchButton) {
        _torchButton = [VinVerticalButton buttonWithType:UIButtonTypeCustom];
        [_torchButton addTarget:self action:@selector(torchButtonClick) forControlEvents:UIControlEventTouchUpInside];
        UIImage * normal = [UIImage imageNamed:@"VinImageResource.bundle/shoudiantong"];
        [_torchButton setImage:normal forState:UIControlStateNormal];
        
        [_torchButton setTitle:@"手电筒" forState:UIControlStateNormal];
        _torchButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [[_torchButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        _torchButton.contentEdgeInsets = UIEdgeInsetsMake(9, 7, 9, 7);
        [_torchButton addTarget:self action:@selector(torchButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _torchButton;
}


- (UILabel *)centerTipLabel {
    if (!_centerTipLabel) {
        _centerTipLabel = [[UILabel alloc] init];
        _centerTipLabel.text = @"将框对准VIN码";
        _centerTipLabel.textColor = [UIColor whiteColor];
        _centerTipLabel.font = [UIFont systemFontOfSize:13];
        _centerTipLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _centerTipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _centerTipLabel;
}


- (UIImageView *)scanLine {
    if (!_scanLine) {
        if (!self.isHorizontalRecognize) {
            _scanLine = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.squareView.squareRect), CGRectGetMinY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame), CGRectGetWidth(self.squareView.squareRect), 3)];
        } else {
            _scanLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.squareView.squareRect), 3)];
            _scanLine.center = CGPointMake(CGRectGetMaxX(self.squareView.squareRect), CGRectGetMidY(self.squareView.squareRect) + CGRectGetMaxY(self.navBar.frame));
            _scanLine.transform = CGAffineTransformMakeRotation(M_PI_2);
        }
        UIImage * image = [UIImage imageNamed:@"VinImageResource.bundle/xian"];
        _scanLine.image = image;
    }
    return _scanLine;
}

- (void)dealloc {
    NSLog(@"Vin Camera Dealloc");
    [self.vinTyper freeVinTyper];
}

@end
