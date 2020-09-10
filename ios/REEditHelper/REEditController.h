//
//  REEditController.h
//  ImageRotateEditDemo
//
//  Created by ocrgroup on 2020/3/30.
//  Copyright © 2020 ocrgroup. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol REEditControllerDelegate <NSObject>

- (void)editController:(UIViewController *)editController cropFinishWithCutImage:(UIImage *)cutImage andSrcImage:(UIImage *)srcImage;

@end

NS_ASSUME_NONNULL_BEGIN

@interface REEditController : UIViewController

@property (nonatomic, weak) id <REEditControllerDelegate> delegate;

@property (nonatomic, copy) void (^getCutImage)(UIImage * cutImage);


- (instancetype)initWithImage:(UIImage *)image andTipString:(NSString *)tipString;



@end

NS_ASSUME_NONNULL_END
