#import "Vinocr.h"
#import "VinManager.h"

@implementation Vinocr

RCT_EXPORT_MODULE()

// Example method
// See // https://facebook.github.io/react-native/docs/native-modules-ios
RCT_REMAP_METHOD(multiply,
                 multiplyWithA:((nonnull) NSNumber*)a withB:(nonnull NSNumber*)b
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject)
{
  NSNumber *result = @([a floatValue] * [b floatValue]);

  resolve(result);
}

// 扫描识别
RCT_EXPORT_METHOD(cameraRequest){

}


// 原生导入
RCT_EXPORT_METHOD(importRequest){
    
}


//MARK:视频流扫描识别
- (void)showVideoStream {
    [VinManager sharedVinManager].delegate = self;
    //若需要识别摩托车Vin设为YES，属性默认值是NO
    [VinManager sharedVinManager].containMotoVin = NO;
    [[VinManager sharedVinManager] recognizeVinCodeByVideoStreamWithController:self usePush:NO andAuthCode:_authorizationCode];
}

//MARK:视频流识别结果回调
- (void)cameraController:(UIViewController *)cameraController videoStreamRecognizeVinFinishWithResult:(NSString *)vinCode srcImage:(UIImage *)srcImage areaCutImage:(UIImage *)areaCutImage andVinImage:(UIImage *)vinImage {
    [cameraController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"%@",vinCode);
    self.recognizeImageView.image = vinImage;
    self.resultArr[0] = vinCode;
    [self loadTableViewData];
    [self.tableView reloadData];
}

@end
