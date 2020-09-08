//
//  REVerticalButton.m
//  ImageRotateEditDemo
//
//  Created by ocrgroup on 2020/3/31.
//  Copyright © 2020 ocrgroup. All rights reserved.
//

#import "REVerticalButton.h"

@implementation REVerticalButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (void)layoutSubviews {
    [super layoutSubviews];
    
    // image center
    CGPoint center;
    center.x = self.frame.size.width/2;
    center.y = self.imageView.frame.size.height/2;
    self.imageView.center = center;
    //text
    CGRect newFrame = [self titleLabel].frame;
    newFrame.origin.x = 0;
    newFrame.origin.y = self.imageView.frame.size.height + 1;
    newFrame.size.width = self.frame.size.width;
    newFrame.size.height = 19;
    
    self.titleLabel.frame = newFrame;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

@end
