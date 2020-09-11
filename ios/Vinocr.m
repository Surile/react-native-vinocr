#import "Vinocr.h"
#import "VinCameraController.h"
#import "REEditController.h"
#import "VinManager.h"

//#define USEPUSH NO

@interface Vinocr () <VinCameraDelegate, VinManagerDelegate>

@property (nonatomic, strong) UINavigationController * navController;

@property (nonatomic, weak) REEditController * editVC;


@property (nonatomic, copy) RCTPromiseResolveBlock resolverCallback;
@property (nonatomic, copy) RCTPromiseRejectBlock rejectCallback;

@end

@implementation Vinocr



RCT_EXPORT_MODULE(Vinocr);


//MARK:视频流识别
RCT_EXPORT_METHOD(vinRecognizeFinish:(NSString *)authCode resolver:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *controller = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        VinCameraController * cameraVC = [[VinCameraController alloc] initWithAuthorizationCode:authCode];
        cameraVC.delegate = self;
        self.cameraVC = cameraVC;
        cameraVC.getVinResultFromOCR = ^(NSDictionary *resultDic) {
            [self.cameraVC dismissViewControllerAnimated:YES completion:^{
                if (resultDic) {
                    resolver(resultDic);
                } else {
                    NSError * err = [NSError errorWithDomain:@"resultDit is nil" code:0 userInfo:nil];
                    reject(@"0",@"cancel",err);
                }
            }];
        };
        
        
        cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [controller presentViewController:cameraVC animated:YES completion:nil];
    });
}


//MARK:导入识别
RCT_EXPORT_METHOD(recogVinImage:(NSString *)authCode imageString:(NSString *)imageString needEdit:(BOOL)needEdit resolver:(RCTPromiseResolveBlock)resolver rejecter:(RCTPromiseRejectBlock)reject) {
    self.resolverCallback = resolver;
    self.rejectCallback = reject;
    NSData *data = [[NSData alloc] initWithBase64EncodedString:imageString options:NSDataBase64DecodingIgnoreUnknownCharacters];

    UIImage * image = [UIImage imageWithData:data];
    if (!image) {
        NSError * err = [NSError errorWithDomain:@"Image file doesn't exist" code:0 userInfo:nil];
        reject(@"0", @"cancel", err);
        return ;
    }
        
    //需要裁切步骤
    if (needEdit) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController * controller = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
            REEditController * editVC = [[REEditController alloc] initWithImage:image andTipString:@"请将车架号移至框内"];
            self.editVC = editVC;
            editVC.getCutImage = ^(UIImage * _Nonnull cutImage) {
                //裁切结束
                [self.editVC dismissViewControllerAnimated:YES completion:^{
                    [VinManager sharedVinManager].delegate = self;
                    [[VinManager sharedVinManager] recognizeVinCodeWithPhoto:cutImage andAuthCode:authCode];
                    
                }];
            };
            
            editVC.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [controller presentViewController:editVC animated:YES completion:nil];
            
        });
    } else {
        //无需编辑 直接识别
        [VinManager sharedVinManager].delegate = self;
        [[VinManager sharedVinManager] recognizeVinCodeWithPhoto:image andAuthCode:authCode];
    }
        
}


#pragma mark - VinManager Delegate
- (void)photoRecognizeFinishWithResult:(NSString *)vinCode srcImage:(UIImage *)srcImage vinImage:(UIImage *)vinImage andErrorCode:(int)errorCode {
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setValue:vinCode forKey:@"vinStr"];
    
    [dict setValue:@(errorCode) forKey:@"errorCode"];
    
    // 获取tmp目录路径
    NSString *tmpDir = NSTemporaryDirectory();
    
    //vin二值化裁切图
    NSString * vinPath = [tmpDir stringByAppendingPathComponent:@"vinImagePath.jpg"];
    NSData * vinData = UIImageJPEGRepresentation(vinImage, 0.8);
    [vinData writeToFile:vinPath atomically:YES];
    [dict setValue:vinPath forKey:@"vinImagePath"];
    
    
    //vin二值化裁切图
    NSString * srcPath = [tmpDir stringByAppendingPathComponent:@"vinSrcImagePath.jpg"];
    NSData * srcData = UIImageJPEGRepresentation(srcImage, 0.8);
    [srcData writeToFile:srcPath atomically:YES];
    [dict setValue:srcPath forKey:@"vinSrcImagePath"];
    self.resolverCallback(dict.copy);
    
}

- (void)backButtonClickWithVinCamera:(UIViewController *)cameraController {
    [self.cameraVC dismissViewControllerAnimated:YES completion:^{
        
    }];
}


@end

