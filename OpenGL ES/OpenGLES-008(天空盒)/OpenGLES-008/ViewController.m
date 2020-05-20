//
//  ViewController.m
//  OpenGLES-008
//
//  Created by 段雨田 on 2020/5/13.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"
#import "starship.h"
#import "MySkyBoxEffect.h"

@interface ViewController ()

//上下文
@property(nonatomic, strong) EAGLContext *myContext;

//基于opengl渲染的简单照明和阴影系统
@property(nonatomic, strong) GLKBaseEffect *baseEffect;

//天空盒子效果
@property (nonatomic, strong) MySkyBoxEffect *skyboxEffect;

//眼睛的位置
@property (nonatomic, assign, readwrite) GLKVector3 eyePosition;

//观察者位置
@property (nonatomic, assign) GLKVector3 lookAtPosition;

//观察者向上的方向的世界坐标系的方向
@property (nonatomic, assign) GLKVector3 upVector;

//旋转角度
@property (nonatomic, assign) float angle;

// BUFFER 顶点\法线
@property (nonatomic, assign) GLuint myPositionBuffer;
@property (nonatomic, assign) GLuint myNormalBuffer;

//开关
@property (nonatomic,strong) UISwitch *myPauseSwitch;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setUpRC];

  //设置开关并添加到屏幕上
  self.myPauseSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 30, 44, 44)];
  [self.view addSubview:self.myPauseSwitch];
  
}

- (void)setUpRC {
    
  //! 新建上下文
  self.myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  GLKView *view = (GLKView *)self.view;
  view.context = self.myContext;
  view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  
  [EAGLContext setCurrentContext:self.myContext];
  
  
  /* 视图矩阵 3个position
   * eyePostion
   * lookAtPosition
   *
   *
   */
  
  //! 眼睛的位置
  self.eyePosition = GLKVector3Make(0.0f, 10.0f, 10.0f);
  //! 观察的物体的位置 -> 让物体处于中心
  self.lookAtPosition = GLKVector3Make(0.0f, 0.0f, 0.0f);
  //! 观察者的朝向，让眼睛往上看
  self.upVector = GLKVector3Make(0.0f, 1.0f, 0.0f);
  
  //!
  self.baseEffect = [[GLKBaseEffect alloc] init];
  self.baseEffect.light0.enabled = GL_TRUE;
  self.baseEffect.light0.position = GLKVector4Make(0.0f, 0.0f, 2.0f, 1.0f);
  ///1 反射光颜色
  self.baseEffect.light0.specularColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.0f);
  ///! 漫反射颜色
  self.baseEffect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);
  
  
  /* 计算光照的策略:
    GLKLightingTypePerVertex 在每一个顶点上作光照的计算
    GLKLightingTypePerPixel 在每一个片段上做光照的计算
   */
  self.baseEffect.lightingType = GLKLightingTypePerPixel;
  
  //！ 每次旋转角度
  self.angle = 0.5f;
  
  //! 设置旋转矩阵
  [self setMatrices];
  
  //! OES扩展类 设置顶点缓冲区
  glGenVertexArraysOES(1, &_myPositionBuffer);
  glBindVertexArrayOES(_myPositionBuffer);
  
  //!
  /* 创建VBO的的步骤
   1. 生成缓冲区标记
   2. 绑定缓冲区
   3. 将顶点数据拷贝到缓冲区
   
   */
  GLuint buffer;
  glGenBuffers(1, &buffer);
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  
  /*
  
      GL_STATIC_DRAW
      GL_STATIC_READ
      GL_STATIC_COPY
   
      GL_DYNAMIC_DRAW
      GL_DYNAMIC_READ
      GL_DYNAMIC_COPY
   
      GL_STREAM_DRAW
      GL_STREAM_READ
      GL_STREAM_COPY
   
   ”static“表示VBO中的数据将不会被改变(一次指定，多次使用)
   ”dynamic“表示数据将会被频繁改动（反复指定与使用）
   ”stream“表示每帧数据都要改变（一次指定一次使用）。
   
   ”draw“表示数据将被发送到GPU以待绘制（应用程序 到 GL），
   ”read“表示数据将被客户端程序读取（GL 到 应用程序），”
   
   */
  glBufferData(GL_ARRAY_BUFFER, sizeof(starshipPositions), starshipPositions, GL_STATIC_DRAW);

  glEnableVertexAttribArray(GLKVertexAttribPosition);

  glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);

  //给buffer重新绑定
  //1.创建缓存对象并返回缓存对象的标识符
  glGenBuffers(1, &buffer);
  //将缓存对象对应到相应的缓存上
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  //数据拷贝到缓存对象
  //starshipNormals 飞机模型光照法线
  glBufferData(GL_ARRAY_BUFFER, sizeof(starshipNormals), starshipNormals, GL_STATIC_DRAW);

  //glEnableVertexAttribArray启用指定属性
  glEnableVertexAttribArray(GLKVertexAttribNormal);
  glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, NULL);

   //开启背面剔除
   glEnable(GL_CULL_FACE);
   
   //开启深度测试
   glEnable(GL_DEPTH_TEST);
   
   // 加载纹理图片
   NSString *path = [[NSBundle bundleForClass:[self class]]
                     pathForResource:@"skybox3" ofType:@"png"];
  
   NSError *error = nil;
   
   //获取纹理信息
   GLKTextureInfo* textureInfo = [GLKTextureLoader
                                  cubeMapWithContentsOfFile:path
                                  options:nil
                                  error:&error];
   if (error) {
       NSLog(@"error %@", error);
   }
   // 配置天空盒特效
   self.skyboxEffect = [[MySkyBoxEffect alloc] init];
   //纹理贴图的名字
   self.skyboxEffect.textureCubeMap.name = textureInfo.name;
   //纹理贴图的标记
   self.skyboxEffect.textureCubeMap.target = textureInfo.target;
   
   // 天空盒的长宽高
   self.skyboxEffect.xSize = 6.0f;
   self.skyboxEffect.ySize = 6.0f;
   self.skyboxEffect.zSize = 6.0f;

}

//更新变换矩阵
- (void)setMatrices {
  
  //！ 设置纵横比
  const GLfloat aspectRatio = (GLfloat)self.view.bounds.size.width / self.view.bounds.size.height;
  
  //! 修改投影矩阵
  self.baseEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0f), aspectRatio, 0.1f, 20.0f);
  
  
  //!
  self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(self.eyePosition.x,
                                                                   self.eyePosition.y,
                                                                   self.eyePosition.z,
                                                                   self.lookAtPosition.x,
                                                                   self.lookAtPosition.y,
                                                                   self.lookAtPosition.z,
                                                                   self.upVector.x,
                                                                   self.upVector.y,
                                                                   self.upVector.z);
  
  ///! 角度累+
  self.angle += 0.01f;
    
  //! 眼睛也要变化，调整观察者的位置
  self.eyePosition = GLKVector3Make(-5.0f * sinf(self.angle),
                                    -5.0f,
                                    -5.5f * cosf(self.angle));
  
  //! 调整 所观察的物体的位置
  self.lookAtPosition = GLKVector3Make(0.0f,
                                       1.5+ -5.0 * sinf(0.3 * self.angle),
                                       0.0f);
  
    
  
  
}

/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  
  glClearColor(0.5f, 0.1f, 0.1f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  
  //! 非暂停状态
  if (self.myPauseSwitch.on == NO) {
    ///! 更新视图变换
    [self setMatrices];
  }
  
    
  //! 更新 盒子/投影矩阵\视图矩阵
   
  self.skyboxEffect.center = self.eyePosition;
  self.skyboxEffect.transform.projectionMatrix = self.baseEffect.transform.projectionMatrix;
  self.skyboxEffect.transform.modelviewMatrix = self.baseEffect.transform.modelviewMatrix;
   
  //! 准备绘制天空盒子
  [self.skyboxEffect prepareToDraw];
    
    /* 对比 OpenGL
     *  1. gluInitDisplayMode(GLUT_DOUBLE|GLUT_DEPTH)
     *  2. 每一帧绘制的时候，清空深度缓冲区: glClear(GLUT_DOUBLE|GLUT_DEPTH)
     *  3. 关闭存储深度操作 glDepthMark()
     */
    
    //! 画盒子的时候，先关闭深度测试
  glDepthMask(false);

  //!
  [self.skyboxEffect draw];
    
  //! 开启深度缓冲区
  glDepthMask(true);
    
  //! 清空缓冲区/纹理
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
  glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
   
  glBindVertexArrayOES(self.myPositionBuffer);
  //! 绘制飞机
  for (int i = 0; i < starshipMaterials; i++) {
    //设置材质的漫反射颜色
    self.baseEffect.material.diffuseColor = GLKVector4Make(starshipDiffuses[i][0], starshipDiffuses[i][1], starshipDiffuses[i][2], 1.0f);
             
    //设置反射光颜色
    self.baseEffect.material.specularColor = GLKVector4Make(starshipSpeculars[i][0], starshipSpeculars[i][1], starshipSpeculars[i][2], 1.0f);
             
    //飞船准备绘制
    [self.baseEffect prepareToDraw];
            
    //绘制
    /*
      glDrawArrays (GLenum mode, GLint first, GLsizei count);提供绘制功能。当采用顶点数组方式绘制图形时，使用该函数。该函数根据顶点数组中的坐标数据和指定的模式，进行绘制。
      参数列表:
      mode，绘制方式，OpenGL2.0以后提供以下参数：GL_POINTS、GL_LINES、GL_LINE_LOOP、GL_LINE_STRIP、GL_TRIANGLES、GL_TRIANGLE_STRIP、GL_TRIANGLE_FAN。
      first，从数组缓存中的哪一位开始绘制，一般为0。
      count，数组中顶点的数量。
             
     */
    glDrawArrays(GL_TRIANGLES, starshipFirsts[i], starshipCounts[i]);
      
  }
    
  
  
}

@end
