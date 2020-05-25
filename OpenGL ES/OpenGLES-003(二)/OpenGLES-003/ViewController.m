//
//  ViewController.m
//  OpenGLES-003
//  金字塔渲染
//  Created by 段雨田 on 2020/5/9.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) EAGLContext *mContext;
///! 接管底层实现
@property (nonatomic, strong) GLKBaseEffect *mEffect;
///！ 索引个数
@property (nonatomic, assign) int count;

//! 旋转度数
@property (nonatomic, assign) float xDegree;
@property (nonatomic, assign) float yDegree;
@property (nonatomic, assign) float zDegree;

///! 是否能在对应的轴旋转
@property (nonatomic, assign) BOOL XB;
@property (nonatomic, assign) BOOL YB;
@property (nonatomic, assign) BOOL ZB;


@end

@implementation ViewController {
  
  ///! 定时器
  dispatch_source_t timer;
  
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  //! 1.新建图层
  [self setupContext];
  //! 2. 渲染图形
  [self render];
}

- (IBAction)XClick:(id)sender {
  _XB = !_XB;
}

- (IBAction)YClick:(id)sender {
  _YB = !_YB;
}

- (IBAction)ZClick:(id)sender {
  _ZB = !_ZB;
}

#pragma mark -

- (void)setupContext {
  
  ///! 新建OpenGL ES 上下文
  self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  //2 GLKView
  GLKView *view = (GLKView *)self.view;
  
  view.context = self.mContext;
  
  view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  
  [EAGLContext setCurrentContext:self.mContext];
  
  ///! 深度测试
  glEnable(GL_DEPTH_TEST);
  
  
}

- (void)render {
  

  //1.顶点数据
  //前3个元素，是顶点数据xyz；中间3个元素，是顶点颜色值rgb，最后2个是纹理坐标st
  GLfloat attrArr[] =
  {
       
    -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
      
    0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
      
    -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
      
    0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
       
    0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    
  };
  
    
  //2.绘图索引：前面两个是底部的索引顺序， 后面4个 是四侧索引顺序
    
  GLuint indices[] =
  {
    
    0, 3, 2,
    0, 1, 3,
    0, 2, 4,
    0, 4, 1,
    2, 3, 4,
    1, 4, 3,
    
  };
  
  
  //！ 顶点的个数
  self.count = sizeof(indices)/sizeof(GLuint);
  
  ///! 将顶点数组 放入 到 数组 缓冲区
  GLuint buffer;
  glGenBuffers(1, &buffer);
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  ///! copy
  glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
  
  ///! 写入索引数组 到 索引数组缓冲区
  GLuint index;
  glGenBuffers(1, &index);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
  //! copy
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
  
  
  ///! 使用顶点数据
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  
  ///! 传递数据  链接数据
  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL+0);
  
  //! 读取颜色数据
  glEnableVertexAttribArray(GLKVertexAttribColor);
  glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL+3);
  
  ///! 读取纹理数据(GLKVertexAttribTexCoord0 和 GLKVertexAttribTexCoord1 没啥区别 )
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL+6);

  
  //!9 获取纹理 路径
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cTest" ofType:@"jpg"];
  
  
  ///! 10
  self.mEffect = [[GLKBaseEffect alloc] init];
  ///! 可以使用纹理
  self.mEffect.texture2d0.enabled = GL_TRUE;
 
  ///! 设置纹理的读取逻辑
  NSDictionary *options = @{
    GLKTextureLoaderOriginBottomLeft: @"1", //! 是否从左下角开始加载纹理，1表示YES
  };

  ///! 设置纹理的信息
  GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:NULL];
  //! 从信息里面 读取 name
  self.mEffect.texture2d0.name = textureInfo.name;

  
  ///! 11. 设置透视投影
  
  CGSize size = self.view.bounds.size;
  
  ///! 获取 纵横比
  float aspect = fabs(size.width / size.height);
  
  /* ! 投影矩阵
   * 视场角度 GLKMathDegreesToRadians 可以把度数转为弧度
   
   
   */
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.0f);
  
  ///! 放大
  projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
  
  
  self.mEffect.transform.projectionMatrix = projectionMatrix;
  
  
  
  /* 12. 模型视图变换矩阵
   * 原矩阵，这里使用单元矩阵 GLKMatrix4Identity
   * 向z轴 移动 负2.0f,向屏幕深度上移动。
   */
  GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
  
  self.mEffect.transform.modelviewMatrix = modelViewMatrix;
  
  
  ///! 开启定时器
  double seconds = 0.1;
  
  timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
  
  dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC, 0.0f);
  
  dispatch_source_set_event_handler(timer, ^{
    
    self.xDegree += 0.1f * self.XB;
    self.yDegree += 0.1f * self.YB;
    self.zDegree += 0.1f * self.ZB;

  });
  
  dispatch_resume(timer);
  
  
}


///! 内置方法，调用
- (void)update {
  
  ///! 更新变化
  
  GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -2.0f);
  
  ///! 整合 各个旋转矩阵
  modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, _xDegree);
  modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, _yDegree);
  modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, _zDegree);
  
  self.mEffect.transform.modelviewMatrix = modelViewMatrix;
  
  
  
}

#pragma - GLKViewDelegate
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  
  glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
  
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  ///! 准备绘制
  [self.mEffect prepareToDraw];
  
  
  ///! 索引绘制
  glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
  
  
}

@end
