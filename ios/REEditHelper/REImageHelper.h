//
//  REImageHelper.h
//  ImageRotateEditDemo
//
//  Created by ocrgroup on 2020/3/30.
//  Copyright © 2020 ocrgroup. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface REImageHelper : NSObject

+ (CGRect)calculateImageViewRectWithImageSize:(CGSize)imageSize andViewSize:(CGSize)viewSize;

+ (UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation;

+ (UIImage *)fixOrientation:(UIImage *)aImage;

@end

NS_ASSUME_NONNULL_END
