//
//  VinSquareView.h
//  VinDemo
//
//  Created by ocrgroup on 2018/3/14.
//  Copyright © 2018年 ocrgroup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VinSquareView : UIView


@property (nonatomic, assign) CGRect squareRect;


@property (assign, nonatomic) BOOL leftHidden;
@property (assign, nonatomic) BOOL rightHidden;
@property (assign, nonatomic) BOOL topHidden;
@property (assign, nonatomic) BOOL bottomHidden;



/// 自定义init方法
/// @param frame 黑色遮罩的frame
/// @param margin 左右边距
/// @param bottomHeight 底部留白
/// @param squareRatio 方框的宽高比
- (instancetype)initWithFrame:(CGRect)frame margin:(CGFloat)margin bottomHeight:(CGFloat)bottomHeight andSquareRatio:(CGFloat)squareRatio;

@end
