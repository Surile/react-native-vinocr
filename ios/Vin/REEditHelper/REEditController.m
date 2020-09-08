//
//  REEditController.m
//  ImageRotateEditDemo
//
//  Created by ocrgroup on 2020/3/30.
//  Copyright © 2020 ocrgroup. All rights reserved.
//

#import "REEditController.h"
#import "REImageHelper.h"
#import "REVerticalButton.h"

#define MASKALPHA 0.5


#define SCREENH [UIScreen mainScreen].bounds.size.height
#define SCREENW [UIScreen mainScreen].bounds.size.width

//iPhone X顶部状态栏安全区
#define SafeAreaStatusBarHeight (isIPhoneXSeries() ? 24 : 0)

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

@interface REEditController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton * backButton;
@property (nonatomic, strong) UIButton * finishButton;


@property (nonatomic, strong) UIImage * srcImage;

@property (nonatomic, strong) UIImage * currentImage;

@property (nonatomic, strong) UIImageView * imageView;

@property (nonatomic, assign) CGRect cropControlRect;
@property (nonatomic, assign) CGRect cropRectToImage;

@property (nonatomic, strong) UIView * topMask;
@property (nonatomic, strong) UIView * bottomMask;

@property (nonatomic, strong) UIRotationGestureRecognizer  * rotateGesture;

@property (nonatomic, strong) UIPinchGestureRecognizer * pinchGesture;

@property (nonatomic, strong) UIPanGestureRecognizer * panGesture;

@property (nonatomic, assign) CGFloat sizeScale;
@property (nonatomic, assign) CGFloat angle;

@property (nonatomic, strong) UIView * tipView;
@property (nonatomic, strong) UILabel * tipLabel;

@property (nonatomic, strong) UIImageView * danzhiImageView;
@property (nonatomic, strong) UILabel * danzhiLabel;
@property (nonatomic, strong) UIImageView * suofangImageView;
@property (nonatomic, strong) UILabel * suofangLabel;
@property (nonatomic, strong) UIImageView * xuanzhuanImageView;
@property (nonatomic, strong) UILabel * xuanzhuanLabel;

@property (nonatomic, strong) UIButton * closeTipButton;


@property (nonatomic, strong) UILabel * cutTipLabel;

@property (nonatomic, strong) REVerticalButton * leftRotateButton;
@property (nonatomic, strong) REVerticalButton * rightRotateButton;

@end

@implementation REEditController

- (instancetype)initWithImage:(UIImage *)image andTipString:(NSString *)tipString
{
    self = [super init];
    if (self) {
        UIImage * newImage = [REImageHelper fixOrientation:image];
        self.srcImage = newImage;
        self.currentImage = newImage;
        self.imageView.image = newImage;
        if (tipString != nil) {
            self.cutTipLabel.text = tipString;
        }
        
       
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addGestureRecognizer:self.pinchGesture];
    [self.view addGestureRecognizer:self.rotateGesture];
    [self.view addGestureRecognizer:self.panGesture];
    
    [self baseConfig];
    
    [self prepareUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
//    self.navigationController.interactivePopGestureRecognizer.delegate = self;
//    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    self.navigationController.navigationBarHidden = YES;
    
}

- (void)baseConfig {
    self.sizeScale = 1;
    self.view.backgroundColor = [UIColor blackColor];
    self.view.layer.masksToBounds = YES;
    
    //MARK:此处配置裁切框大小
    self.cropControlRect = CGRectMake(0, SCREENH * 0.5 - 50, SCREENW, 120);
    
}

- (void)prepareUI {
    
    [self.view addSubview:self.imageView];
    
    [self.view addSubview:self.topMask];
    
    [self.view addSubview:self.bottomMask];
    
    [self.view addSubview:self.backButton];
    
    [self.view addSubview:self.finishButton];
    
    [self.view addSubview:self.cutTipLabel];
    
    [self.view addSubview:self.leftRotateButton];
    [self.view addSubview:self.rightRotateButton];
    
    //提示
    [self.view addSubview:self.tipView];
    [self.tipView addSubview:self.tipLabel];
    [self.tipView addSubview:self.danzhiImageView];
    [self.tipView addSubview:self.danzhiLabel];
    [self.tipView addSubview:self.suofangImageView];
    [self.tipView addSubview:self.suofangLabel];
    [self.tipView addSubview:self.xuanzhuanImageView];
    [self.tipView addSubview:self.xuanzhuanLabel];
    [self.tipView addSubview:self.closeTipButton];
    
    [self frameSetup];
}

- (void)frameSetup {
    
    self.backButton.frame = CGRectMake(5, 20 + SafeAreaStatusBarHeight, 46, 46);
    
    self.topMask.frame = CGRectMake(0, 0, SCREENW, CGRectGetMinY(self.cropControlRect));
    self.bottomMask.frame = CGRectMake(0, CGRectGetMaxY(self.cropControlRect), SCREENW, SCREENH - CGRectGetMaxY(self.cropControlRect));
    
    self.imageView.frame = [REImageHelper calculateImageViewRectWithImageSize:self.currentImage.size andViewSize:CGSizeMake(SCREENW, SCREENH)];
    self.cropRectToImage = CGRectMake(CGRectGetMinX(self.cropControlRect) - CGRectGetMinX(self.imageView.frame), CGRectGetMinY(self.cropControlRect) - CGRectGetMinY(self.imageView.frame), CGRectGetWidth(self.cropControlRect), CGRectGetHeight(self.cropControlRect));
    
    self.finishButton.frame = CGRectMake(SCREENW * 0.5 - 45, SCREENH - 90, 90, 45);
    self.finishButton.layer.cornerRadius = 45 * 0.5;
    self.finishButton.layer.masksToBounds = YES;
    
    
    [self.cutTipLabel sizeToFit];
    self.cutTipLabel.center = CGPointMake(SCREENW * 0.5, CGRectGetMaxY(self.cropControlRect) + 40);
    
    
    self.leftRotateButton.frame = CGRectMake(0, 0, 60, 45);
    self.leftRotateButton.center = CGPointMake(50, CGRectGetMaxY(self.cropControlRect) + 40);
    
    self.rightRotateButton.frame = CGRectMake(0, 0, 60, 45);
    self.rightRotateButton.center = CGPointMake(SCREENW - 50, CGRectGetMaxY(self.cropControlRect) + 40);
    
    
    //提示
    CGFloat tipViewWidth = SCREENW - 2 * 30;
    self.tipView.frame = CGRectMake(30, 100 + SafeAreaStatusBarHeight, tipViewWidth, 110);
    self.tipView.layer.cornerRadius = 8;
    self.tipView.layer.masksToBounds = YES;
    
    
    [self.tipLabel sizeToFit];
    self.tipLabel.center = CGPointMake(tipViewWidth * 0.5, 15);
    
    CGFloat distance = SCREENW / 4.0;
    self.danzhiImageView.frame = CGRectMake(0, 0, 53, 53);
    self.danzhiImageView.center = CGPointMake(distance - 30, 60);
    
    [self.danzhiLabel sizeToFit];
    self.danzhiLabel.center = CGPointMake(self.danzhiImageView.center.x, self.danzhiImageView.center.y + 35);
    
    self.suofangImageView.frame = CGRectMake(0, 0, 53, 53);
    self.suofangImageView.center = CGPointMake(tipViewWidth * 0.5, 60);
    
    [self.suofangLabel sizeToFit];
    self.suofangLabel.center = CGPointMake(self.suofangImageView.center.x, self.suofangImageView.center.y + 35);
    
    self.xuanzhuanImageView.frame = CGRectMake(0, 0, 53, 53);
    self.xuanzhuanImageView.center = CGPointMake(self.suofangImageView.center.x + distance, 60);
    
    [self.xuanzhuanLabel sizeToFit];
    self.xuanzhuanLabel.center = CGPointMake(self.xuanzhuanImageView.center.x, self.xuanzhuanImageView.center.y + 35);
    
    
    self.closeTipButton.frame = CGRectMake(0, 0, 30, 30);
    self.closeTipButton.center = CGPointMake(tipViewWidth - 15, 15);
    
    
}

#pragma mark - Gesture

- (void)rotate:(UIRotationGestureRecognizer *)sender {
    self.angle += sender.rotation;
//    NSLog(@"angle%.2lf", self.angle);

    //计算旋转的变换矩阵并且赋值
    self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, sender.rotation);
    //旋转角度清零
    sender.rotation = 0;
}

- (void)pan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.view];
    self.imageView.center = CGPointMake(self.imageView.center.x + translation.x,                                         self.imageView.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.view];
   
}

- (void)pinch:(UIPinchGestureRecognizer *)sender {
    
    self.sizeScale += sender.scale - 1;
//    NSLog(@"sizeScal:%.2lf",self.sizeScale);
    //获取监控视图图像
    UIImageView* iView = self.imageView;
    //对图像视图对象进行矩阵变换计算并赋值
    //CGAffineTransformScale通过缩放的方式产生一个新的矩阵
    //P1：原来的矩阵
    //P2：x方向上的缩放比例
    //P3：y方向上的缩放比例
    iView.transform = CGAffineTransformScale(iView.transform, sender.scale, sender.scale);

    //将缩放值归位为单位值，由于响应函数是在每个瞬间都调用的（不管手指是否有滑动）
    //如果不归零，缩放后保持手指触屏位置不变时，图片也会一直按照上一次缩放的比例继续缩放。
    //scale=1原来的大小
    sender.scale = 1;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - 点击事件
- (void)leftRotateButtonClick {
    self.currentImage = [REImageHelper image:self.currentImage rotation:UIImageOrientationLeft];
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image = self.currentImage;
    self.imageView.frame = [REImageHelper calculateImageViewRectWithImageSize:self.currentImage.size andViewSize:CGSizeMake(SCREENW, SCREENH)];
    self.sizeScale = 1;
    self.angle = 0;
}

- (void)rightRotateButtonClick {
    self.currentImage = [REImageHelper image:self.currentImage rotation:UIImageOrientationRight];
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image = self.currentImage;
    self.imageView.frame = [REImageHelper calculateImageViewRectWithImageSize:self.currentImage.size andViewSize:CGSizeMake(SCREENW, SCREENH)];
    self.sizeScale = 1;
    self.angle = 0;
}

- (void)backButtonClick {
    if (self.navigationController != nil) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)closeTipButtonClick {
    self.tipView.hidden = YES;
}

- (void)finishButtonClick {
    if (self.currentImage == nil) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"图片为空，无法裁剪！" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];

        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        return ;
    }
    
    UIImage *croppedImage = [self cropImage];
    
    if ([self.delegate respondsToSelector:@selector(editController:cropFinishWithCutImage:andSrcImage:)]) {
        [self.delegate editController:self cropFinishWithCutImage:croppedImage andSrcImage:self.srcImage];
    } else {
        NSLog(@"%s %d delegate:%@ didn't implement selector editController:cropFinishWithImage:",__FUNCTION__,__LINE__, self.delegate);
    }
}

- (UIImage *)cropImage {
    CGRect imageViewRect = self.imageView.frame;
    
    CGFloat x = self.cropControlRect.origin.x - imageViewRect.origin.x;
    CGFloat y = self.cropControlRect.origin.y - imageViewRect.origin.y;
    
    CGFloat controlWidth = CGRectGetWidth(imageViewRect);
    CGFloat controlHeight = CGRectGetHeight(imageViewRect);
    
    
    UIImage *rotateImage = [self getRotationImage:self.currentImage rotation:self.angle point:CGPointMake(self.currentImage.size.width * 0.5, self.currentImage.size.height * 0.5)];
    

    CGFloat imageWidth = rotateImage.size.width;
    CGFloat imageHeight = rotateImage.size.height;
    
    CGFloat ratio = 1;
    if (imageWidth / imageHeight > controlWidth / controlHeight) {
        ratio = imageHeight / controlHeight;
    } else {
        ratio = imageWidth / controlWidth;
    }
    
    CGRect rcCrop = CGRectMake(x * ratio, y * ratio, CGRectGetWidth(self.cropControlRect) * ratio, CGRectGetHeight(self.cropControlRect) * ratio);
    CGImageRef imageRef = rotateImage.CGImage;
    CGImageRef subImageRef = CGImageCreateWithImageInRect(imageRef, rcCrop);
    UIGraphicsBeginImageContext(rcCrop.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, rcCrop, subImageRef);
    UIImage *cropImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    CGImageRelease(subImageRef);
    return cropImage;
    
    return nil;
}

- (UIImage *)getRotationImage:(UIImage *)image rotation:(CGFloat)rotation point:(CGPoint)point {
    NSInteger num = (NSInteger)(floor(rotation));
    if (num == rotation && num % 360 == 0) {
        return image;
    }
    
    CGAffineTransform rotatedTransform = CGAffineTransformMakeRotation(rotation);
    CGRect imageFrame = CGRectZero;
    imageFrame.size = image.size;
    imageFrame = CGRectApplyAffineTransform(imageFrame, rotatedTransform);
    CGSize rotatedSize = imageFrame.size;

    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotatedSize.width * 0.5, rotatedSize.height * 0.5);
    CGContextRotateCTM(context, rotation);
    CGContextTranslateCTM(context, -image.size.width * 0.5, -image.size.height * 0.5);
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    UIImage * rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotatedImage;
    
}


#pragma mark - lazy load
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (UIView *)topMask {
    if (!_topMask) {
        _topMask = [[UIView alloc] init];
        _topMask.backgroundColor = [UIColor colorWithWhite:0 alpha:MASKALPHA];
    }
    return _topMask;
}

- (UIView *)bottomMask {
    if (!_bottomMask) {
        _bottomMask = [[UIView alloc] init];
        _bottomMask.backgroundColor = [UIColor colorWithWhite:0 alpha:MASKALPHA];
    }
    return _bottomMask;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage * backImage = [UIImage imageNamed:@"REImageResource.bundle/fanhui"];
        [_backButton setImage:backImage forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [[_backButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        _backButton.contentEdgeInsets = UIEdgeInsetsMake(12, 0, 12, 0);
    }
    return _backButton;
}

- (UIButton *)finishButton {
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_finishButton setTitle:@"确定裁切" forState:UIControlStateNormal];
        _finishButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [_finishButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_finishButton setBackgroundColor:[UIColor whiteColor]];
        [_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (UIRotationGestureRecognizer *)rotateGesture {
    if (!_rotateGesture) {
        _rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
        _rotateGesture.delegate = self;
    }
    return _rotateGesture;
}

- (UIPinchGestureRecognizer *)pinchGesture {
    if (!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        _pinchGesture.delegate = self;
    }
    return _pinchGesture;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}

- (UIView *)tipView {
    if (!_tipView) {
        _tipView = [[UIView alloc] init];
        _tipView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    }
    return _tipView;
}

- (UIImageView *)danzhiImageView {
    if (!_danzhiImageView) {
        _danzhiImageView = [[UIImageView alloc] init];
        UIImage * danzhiImage = [UIImage imageNamed:@"REImageResource.bundle/danzhi"];
        _danzhiImageView.image = danzhiImage;
        _danzhiImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _danzhiImageView;
}

- (UIImageView *)suofangImageView {
    if (!_suofangImageView) {
        _suofangImageView = [[UIImageView alloc] init];
        UIImage * suofangImage = [UIImage imageNamed:@"REImageResource.bundle/fangda"];
        _suofangImageView.image = suofangImage;
        _suofangImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _suofangImageView;
}

- (UIImageView *)xuanzhuanImageView {
    if (!_xuanzhuanImageView) {
        _xuanzhuanImageView = [[UIImageView alloc] init];
        UIImage * xuanzhuanImage = [UIImage imageNamed:@"REImageResource.bundle/shoushixuanzhuan"];
        _xuanzhuanImageView.image = xuanzhuanImage;
        _xuanzhuanImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _xuanzhuanImageView;
}

- (UIButton *)closeTipButton {
    if (!_closeTipButton) {
        _closeTipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage * closeImage = [UIImage imageNamed:@"REImageResource.bundle/chaguanbi"];
        [_closeTipButton setImage:closeImage forState:UIControlStateNormal];
        [_closeTipButton addTarget:self action:@selector(closeTipButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [[_closeTipButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        _closeTipButton.contentEdgeInsets = UIEdgeInsetsMake(8, 0, 8, 0);
    }
    return _closeTipButton;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.text = @"操作提示";
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont systemFontOfSize:13];
    }
    return _tipLabel;
}

- (UILabel *)danzhiLabel {
    if (!_danzhiLabel) {
        _danzhiLabel = [[UILabel alloc] init];
        _danzhiLabel.text = @"单指移动";
        _danzhiLabel.textColor = [UIColor whiteColor];
        _danzhiLabel.font = [UIFont systemFontOfSize:13];
    }
    return _danzhiLabel;
}

- (UILabel *)suofangLabel {
    if (!_suofangLabel) {
        _suofangLabel = [[UILabel alloc] init];
        _suofangLabel.text = @"放大/缩小";
        _suofangLabel.textColor = [UIColor whiteColor];
        _suofangLabel.font = [UIFont systemFontOfSize:13];
    }
    return _suofangLabel;
}

- (UILabel *)xuanzhuanLabel {
    if (!_xuanzhuanLabel) {
        _xuanzhuanLabel = [[UILabel alloc] init];
        _xuanzhuanLabel.text = @"旋转";
        _xuanzhuanLabel.textColor = [UIColor whiteColor];
        _xuanzhuanLabel.font = [UIFont systemFontOfSize:13];
    }
    return _xuanzhuanLabel;
}

- (UILabel *)cutTipLabel {
    if (!_cutTipLabel) {
        _cutTipLabel = [[UILabel alloc] init];
        _cutTipLabel.text = @"请将关键信息移入框内";
        _cutTipLabel.textColor = [UIColor whiteColor];
        _cutTipLabel.font = [UIFont systemFontOfSize:19];
    }
    return _cutTipLabel;
}

- (REVerticalButton *)leftRotateButton {
    if (!_leftRotateButton) {
        _leftRotateButton = [REVerticalButton buttonWithType:UIButtonTypeCustom];
        UIImage * zuoxuanImage = [UIImage imageNamed:@"REImageResource.bundle/zuoxuan"];
        [_leftRotateButton setImage:zuoxuanImage forState:UIControlStateNormal];
        [_leftRotateButton addTarget:self action:@selector(leftRotateButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [[_leftRotateButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        [_leftRotateButton setTitle:@"左旋90°" forState:UIControlStateNormal];
        _leftRotateButton.contentEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        _leftRotateButton.titleLabel.font = [UIFont systemFontOfSize:13];
    }
    return _leftRotateButton;
}

- (REVerticalButton *)rightRotateButton {
    if (!_rightRotateButton) {
        _rightRotateButton = [REVerticalButton buttonWithType:UIButtonTypeCustom];
        UIImage * youxuanImage = [UIImage imageNamed:@"REImageResource.bundle/youxuan"];
        [_rightRotateButton setImage:youxuanImage forState:UIControlStateNormal];
        [_rightRotateButton addTarget:self action:@selector(rightRotateButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [[_rightRotateButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
        [_rightRotateButton setTitle:@"右旋90°" forState:UIControlStateNormal];
        _rightRotateButton.contentEdgeInsets = UIEdgeInsetsMake(5, 0, 5, 0);
        _rightRotateButton.titleLabel.font = [UIFont systemFontOfSize:13];
    }
    return _rightRotateButton;
}

@end
