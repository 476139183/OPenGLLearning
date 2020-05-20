//
//  GLContainerView.h
//  OpenGLES-010
//
//  Created by 段雨田 on 2020/5/18.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLContainerView : UIView

//! 图片
@property (nonatomic, strong) UIImage *image;

//! 色温值
@property (nonatomic, assign) CGFloat colorTempValue;

//! 饱和度
@property (nonatomic, assign) CGFloat saturationValue;

@end


