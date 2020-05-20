//
//  GLContainerView.m
//  OpenGLES-010
//
//  Created by 段雨田 on 2020/5/18.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "GLContainerView.h"

#import <AVFoundation/AVFoundation.h>
#import "GLView.h"

@interface GLContainerView()

@property (nonatomic, strong) GLView *glView;

@end

@implementation GLContainerView

#pragma mark - Life Cycle
- (void)awakeFromNib {
  [super awakeFromNib];
  
  [self setupGLView];
  
}

#pragma mark - Setup
- (void)setupGLView {
  
  //! 获取GLView
  self.glView = [[GLView alloc] initWithFrame:self.bounds];
  [self addSubview:self.glView];
  
}

#pragma mark - Private
- (void)layoutGlkView {
    
  //! 1. 获取图片尺寸
  CGSize imageSize = self.image.size;
  //! 根据传递的frmae 计算纵横比等信息， 返回一个 符合 size 的 frame
  CGRect frame = AVMakeRectWithAspectRatioInsideRect(imageSize, self.bounds);
  //！2
  self.glView.frame = frame;
  
  self.glView.contentScaleFactor = imageSize.width / frame.size.width;
}

#pragma mark - Public
- (void)setImage:(UIImage *)image {
  
  //! 设置image
  _image = image;
  //! GLView
  [self layoutGlkView];
  //! 渲染图片
  [self.glView layoutGLViewWithImage:image];
  
}

//修改色温
- (void)setColorTempValue:(CGFloat)colorTempValue {
    
  _colorTempValue = colorTempValue;
  
  self.glView.temperature = colorTempValue;
    
}

//修改饱和度
- (void)setSaturationValue:(CGFloat)saturationValue {
 
  _saturationValue = saturationValue;
  
  self.glView.saturation = saturationValue;
  
}


@end
