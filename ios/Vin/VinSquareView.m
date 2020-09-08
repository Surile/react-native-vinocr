//
//  VinSquareView.m
//  VinDemo
//
//  Created by ocrgroup on 2018/3/14.
//  Copyright © 2018年 ocrgroup. All rights reserved.
//

#import "VinSquareView.h"

#define THEMECOLOR [UIColor colorWithRed:89/255.0 green:212/255.0 blue:209/255.0 alpha:1]


#define SCREENH [UIScreen mainScreen].bounds.size.height
#define SCREENW [UIScreen mainScreen].bounds.size.width

@interface VinSquareView ()

//无论是横屏还是竖屏都按竖屏状态下的左上右上左下右下
@property (nonatomic, assign) CGPoint ptLeftTop;
@property (nonatomic, assign) CGPoint ptRightTop;
@property (nonatomic, assign) CGPoint ptLeftBottom;
@property (nonatomic, assign) CGPoint ptRightBottom;

//黑色遮罩所需
@property (nonatomic, strong) UIBezierPath * bezierPath;

@property (nonatomic, strong) CAShapeLayer * shapeLayer;



@end

@implementation VinSquareView

- (instancetype)initWithFrame:(CGRect)frame margin:(CGFloat)margin bottomHeight:(CGFloat)bottomHeight andSquareRatio:(CGFloat)squareRatio
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.bottomHidden = YES;
        self.leftHidden = YES;
        self.rightHidden = YES;
        self.topHidden = YES;
        if (bottomHeight > CGRectGetHeight(frame)) {
            NSLog(@"bottomHeight is longer than frame height");
            return self;
        }
        
        CGFloat frameRatio = CGRectGetWidth(frame) / (CGRectGetHeight(frame) - bottomHeight);
        CGFloat x,y,h,w;
        if (frameRatio > squareRatio) {//方框更宽一些
            //以height为基础
            h = CGRectGetHeight(frame) - bottomHeight - margin * 2;
            w = h * squareRatio;
        } else {
            w = CGRectGetWidth(frame) - margin * 2;
            h = w / squareRatio;
        }
        
        x = (CGRectGetWidth(frame) - w) * 0.5;
        y = (CGRectGetHeight(frame) - bottomHeight - h) * 0.5;
        
        self.ptLeftTop = CGPointMake(x, y);
        self.ptRightTop = CGPointMake(x + w, y);
        self.ptRightBottom = CGPointMake(x + w, y + h);
        self.ptLeftBottom = CGPointMake(x, y + h);
        [self.layer addSublayer:self.shapeLayer];
        self.layer.masksToBounds = YES;
        
        self.squareRect = CGRectMake(x, y, w, h);
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat lineLength = 30;
    //设置线宽
    CGContextSetLineWidth(context, 2.0f);
    [[UIColor whiteColor] set];
    //画边线
    if (!_bottomHidden) {
        if (SCREENW > SCREENH) {
            //横屏锁定
            CGContextMoveToPoint(context, self.ptLeftBottom.x, self.ptLeftBottom.y);
            CGContextAddLineToPoint(context, self.ptRightBottom.x, self.ptRightBottom.y);
        } else {
            CGContextMoveToPoint(context, self.ptLeftTop.x, self.ptLeftTop.y);
            CGContextAddLineToPoint(context, self.ptLeftBottom.x, self.ptLeftBottom.y);
        }
    }
    if (!_topHidden) {
        if (SCREENW > SCREENH) {
            //横屏锁定
            CGContextMoveToPoint(context, self.ptLeftTop.x,self.ptLeftTop.y);
            CGContextAddLineToPoint(context, self.ptRightTop.x, self.ptRightTop.y);
        } else {
            CGContextMoveToPoint(context, self.ptRightTop.x,self.ptRightTop.y);
            CGContextAddLineToPoint(context, self.ptRightBottom.x, self.ptRightBottom.y);
        }
    }
    
    if (!_leftHidden) {
        if (SCREENW > SCREENH) {
            //横屏锁定
            CGContextMoveToPoint(context, self.ptLeftTop.x,self.ptLeftTop.y);
            CGContextAddLineToPoint(context, self.ptLeftBottom.x, self.ptLeftBottom.y);
        } else {
            CGContextMoveToPoint(context, self.ptLeftTop.x,self.ptLeftTop.y);
            CGContextAddLineToPoint(context, self.ptRightTop.x, self.ptRightTop.y);
        }
    }
    if (!_rightHidden) {
        if (SCREENW > SCREENH) {
            //横屏锁定
            CGContextMoveToPoint(context, self.ptRightTop.x, self.ptRightTop.y);
            CGContextAddLineToPoint(context, self.ptRightBottom.x,self.ptRightBottom.y);
        } else {
            CGContextMoveToPoint(context, self.ptLeftBottom.x, self.ptLeftBottom.y);
            CGContextAddLineToPoint(context, self.ptRightBottom.x,self.ptRightBottom.y);
        }
    }
    CGContextStrokePath(context);
    
    //画角线
    [THEMECOLOR set];
    CGContextMoveToPoint(context,self.ptLeftTop.x + 1, self.ptLeftTop.y + lineLength);
    CGContextAddLineToPoint(context, self.ptLeftTop.x + 1, self.ptLeftTop.y + 1);
    CGContextAddLineToPoint(context, self.ptLeftTop.x + lineLength, self.ptLeftTop.y + 1);
    
    
    CGContextMoveToPoint(context, self.ptRightTop.x - lineLength, self.ptRightTop.y + 1);
    CGContextAddLineToPoint(context, self.ptRightTop.x - 1, self.ptRightTop.y + 1);
    CGContextAddLineToPoint(context, self.ptRightTop.x - 1, self.ptRightTop.y + lineLength);
    
    
    CGContextMoveToPoint(context, self.ptRightBottom.x - 1, self.ptRightBottom.y - lineLength);
    CGContextAddLineToPoint(context, self.ptRightBottom.x - 1, self.ptRightBottom.y - 1);
    CGContextAddLineToPoint(context, self.ptRightBottom.x - lineLength, self.ptRightBottom.y - 1);
    
    CGContextMoveToPoint(context, self.ptLeftBottom.x + lineLength, self.ptLeftBottom.y - 1);
    CGContextAddLineToPoint(context, self.ptLeftBottom.x + 1, self.ptLeftBottom.y - 1);
    CGContextAddLineToPoint(context, self.ptLeftBottom.x + 1, self.ptLeftBottom.y - lineLength);
    
    CGContextStrokePath(context);
    
    //非裁切保留区域则加黑色半透明蒙版
    [self drawNewBezierPath];
}

- (void)drawNewBezierPath {
    [self.bezierPath removeAllPoints];
    
    //外顺内逆
    //如果一直是方框内有遮罩,请注意self.frame宽高是否为0
    [self.bezierPath moveToPoint:CGPointMake(0, 0)];
    [self.bezierPath addLineToPoint:CGPointMake(self.frame.size.width, 0)];
    [self.bezierPath addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    [self.bezierPath addLineToPoint:CGPointMake(0, self.frame.size.height)];
    [self.bezierPath addLineToPoint:CGPointMake(0, 0)];
    [self.bezierPath moveToPoint:self.ptLeftTop];
    [self.bezierPath addLineToPoint:self.ptLeftBottom];
    [self.bezierPath addLineToPoint:self.ptRightBottom];
    [self.bezierPath addLineToPoint:self.ptRightTop];
    [self.bezierPath closePath];
    
    [self.shapeLayer setPath:self.bezierPath.CGPath];
}

#pragma mark - Setter
- (void) setTopHidden:(BOOL)topHidden
{
    _topHidden = topHidden;
    [self setNeedsDisplay];
}

- (void) setLeftHidden:(BOOL)leftHidden
{
    _leftHidden = leftHidden;
    [self setNeedsDisplay];
}

- (void) setBottomHidden:(BOOL)bottomHidden
{
    _bottomHidden = bottomHidden;
    [self setNeedsDisplay];
}

- (void) setRightHidden:(BOOL)rightHidden
{
    _rightHidden = rightHidden;
    [self setNeedsDisplay];
}

#pragma mark - Getter

- (UIBezierPath *)bezierPath {
    if (!_bezierPath) {
        _bezierPath = [UIBezierPath bezierPath];
    }
    return _bezierPath;
}

- (CAShapeLayer *)shapeLayer {
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        [_shapeLayer setFillRule:kCAFillRuleEvenOdd];
        _shapeLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.5].CGColor;
    }
    return _shapeLayer;
}



@end
