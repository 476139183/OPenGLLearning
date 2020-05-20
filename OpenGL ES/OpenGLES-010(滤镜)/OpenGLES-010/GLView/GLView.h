//
//  GLView.h
//  OpenGLES-010
//
//  Created by 段雨田 on 2020/5/18.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLView : UIView {
  
  //! 图层
  CAEAGLLayer *_eaglLayer;
  //! 上下文
  EAGLContext *_context;
  //! 帧缓冲区->色温
  GLuint       _colorTempFramebuffer;
  //! 渲染缓冲区->色温
  GLuint       _colorTempRenderbuffer;
  //! 纹理->色温
  GLuint       _colorTempTexture;
  //! 帧缓冲区->饱和度
  GLuint       _saturatedFramebuffer;
  //! 渲染缓冲区->饱和度
  GLuint       _saturatedRenderBuffer;
  //! 纹理->饱和度
  GLuint       _saturatedTexture;

  //！ 色温 程序
  GLuint       _colorTempProgramHandle;
  //! 饱和度 程序
  GLuint       _saturatedProgramHandle;
}

//色温
@property (nonatomic, assign) CGFloat temperature;
//饱和度
@property (nonatomic, assign) CGFloat saturation;

//将图片加入到GLView上
- (void)layoutGLViewWithImage:(UIImage *)image;


@end


