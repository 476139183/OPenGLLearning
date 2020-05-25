//
//  ViewController.m
//  OpenGLES-001
//
//  Created by 段雨田 on 2020/5/7.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface ViewController () {
  ///! 上下文
  EAGLContext *context;
  
  ///！ 处理 光照和纹理的 着色器
  GLKBaseEffect *mEffect;
  
}

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  ///! 设置 GLES
  [self setUpConfig];
  
  ///! 加载顶点数据
  [self uploadVertexArray];
  
  ///! 加载纹理
  [self uploadTexture];
  
}


- (void)setUpConfig {
  
  ///！ 设置上下文
  context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
  
  if (!context) {
    NSLog(@"context 错误");
    return;
  }
  
  GLKView *view = (GLKView *)self.view;
  
  view.context = context;
  
  ///! 深度缓冲区 颜色缓冲区
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  
  [EAGLContext setCurrentContext:context];
  
  //! 开启深度测试
  glEnable(GL_DEPTH_TEST);
  
  ///！ 设置 清屏 颜色
  glClearColor(0.1, 0.2, 0.3, 1.0);
  
}

- (void)uploadVertexArray {
  
     //第一步：设置顶点数组
     //OpenGLES的世界坐标系是[-1, 1]，故而点(0, 0)是在屏幕的正中间。
     //顶点数据，前3个是顶点坐标x,y,z；后面2个是纹理坐标。
     //纹理坐标系的取值范围是[0, 1]，原点是在左下角。故而点(0, 0)在左下角，点(1, 1)在右上角
     //2个三角形构成
  
  GLfloat vertexData[] = {
    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
    0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
    -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
  };
  
  
  //! 申请一个顶点缓冲区
  GLuint buffer;
  
  ///! 申请缓冲区标示
  glGenBuffers(1, &buffer);
  
  ///！ 将标识符绑定到数组缓冲区
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  
  
  ///! 将顶点数据 从 CPU copy 到 GPU
  /*
   GL_ARRAY_BUFFER:从数组缓冲区copy
   GL_STATIC_DRAW 表示作用：用于绘制
   */
  glBufferData(GL_ARRAY_BUFFER , sizeof(vertexData), vertexData, GL_STATIC_DRAW);
  
  
  /*
   * 告诉它 要作为顶点属性 传递过去 给 GLES
   * GLKVertexAttribPosition 在下一行代码有用
   */
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  
  ///! 规则读取
  /* 前面的 GLKVertexAttribPosition 代表的就是 从 顶点数据读取
   * 读取3个元素
   * 读取的是 浮点类型
   * normalized 要不要做 归一化，我们选择NO
   * 步长：5
   * 读取指针的起点：从0开始
   */
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);

  
  ///! 告诉它 要读取纹理数据
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  
  /* 规则读取:参考 上面的顶点数据
   *
   */
  
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
  
  
  ///！
  
}

- (void)uploadTexture {
  
  ///! 获取纹理路径
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cTest" ofType:@"jpg"];
  
  /* 设置属性，规范
   是否从左下边加载: YES
   GLKTextureLoaderOriginBottomLeft:1
   
   */
  NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
  
  //! 获取纹理信息
  GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:NULL];
  
  ///! 着色器
  mEffect = [[GLKBaseEffect alloc] init];
  
  ///! 是否使用纹理
  mEffect.texture2d0.enabled = GL_TRUE;
  
  ///! 设置纹理
  mEffect.texture2d0.name = textureInfo.name;
  
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {

  ///! 重新设置清屏颜色 surface的清除颜色
  glClearColor(0.3, 0.6, 1.0, 1.0);

  ///! 清理缓冲区 清除surface内容，恢复至初始状态。
  glClear(GL_DEPTH_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  
  ///! 启动着色器
  [mEffect prepareToDraw];
  glDrawArrays(GL_TRIANGLES, 0, 6);
  
}


@end
