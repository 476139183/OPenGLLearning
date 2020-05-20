//
//  ViewController.m
//  OpenGL--005
//
//  Created by 段雨田 on 2020/5/12.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
///!
#import "sphere.h"


//! 场景地球轴倾斜度
static const GLfloat SceneEarthAxialTiltDeg = 23.5f;
//! 月球轨道日数
static const GLfloat SceneDaysPerMoonOrbit = 28.0f;
//! 半径
static const GLfloat SceneMoonRadiusFractionOfEarth = 0.25;
//! 月球距离地球的距离
static const GLfloat SceneMoonDistanceFromEarth = 2.0f;


@interface ViewController ()

@property (nonatomic, strong) EAGLContext *mContext;


//! 顶点 positionBuffer
@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *vertexPositionBuffer;

//! 顶点法线 NormalBuffer
@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *vertexNormalBuffer;

//! 顶点纹理 TextureCoordBuffer
@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *vertextTextureCoordBuffer;

//! 光照、纹理
@property (nonatomic, strong) GLKBaseEffect *baseEffect;

//! 不可变纹理对象数据, 地球纹理对象
@property (nonatomic, strong) GLKTextureInfo *earchTextureInfo;

//! 月亮纹理对象
@property (nonatomic, strong) GLKTextureInfo *moomTextureInfo;


/*! 模型视图矩阵
 * GLKMatrixStackRef CFType 允许一个4*4 矩阵堆栈
 */
@property (nonatomic, assign) GLKMatrixStackRef modelViewMatrixStack;

//! 地球的旋转角度
@property (nonatomic, assign) GLfloat earthRotationAngleDegress;
//! 月亮旋转的角度
@property (nonatomic, assign) GLfloat moonRotationAngleDegress;


@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  ///! 1. 新建 上下文
  self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  ///! 2. 获取GLKview
  GLKView *view = (GLKView *)self.view;

  view.context = self.mContext;
  view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  
  //!
  [EAGLContext setCurrentContext:self.mContext];
  
  ///! 3. 开启深度测试
  glEnable(GL_DEPTH_TEST);
  
  ///! 4. 创建GLBaseEffect
  self.baseEffect = [[GLKBaseEffect alloc] init];
  
  //! 配置
  [self configureLight];
  
  
  ///5.  投影方式
  ///! 纵横比
  GLfloat aspectRatio = self.view.bounds.size.width / self.view.bounds.size.height;
  
  ///! 正投影
  self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0, 1.0, 120.0f);
  
  //! 6 模型视图变换,向屏幕内移动5个像素点
  self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
  
  //! 7.设置颜色
  GLKVector4 colorVector4 = GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f);
  [self setClearColor:colorVector4];
  
  //! 处理顶点数据
  [self bufferData];
  
  
}

- (void)bufferData {

  //! 1. 创建 空矩阵
  self.modelViewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
  
  ///! 2. 为将要 缓存的数据开辟空间
  /*
   * 参数1: 一行的数据大小，也是步长, 这里是 3个GLFloat x,y,z
   * 参数2: 有多少组数据。这里是顶点数
   * 参数3：数据源
   * 参数4: 用途
   */
  self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:(3* sizeof(GLfloat)) numberOfVertices:sizeof(sphereVerts)/(3*sizeof(GLfloat)) bytes:sphereVerts usage:GL_STATIC_DRAW];
  
  
  //! 光照数据
  self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:(3* sizeof(GLfloat)) numberOfVertices:sizeof(sphereNormals)/(3*sizeof(GLfloat)) bytes:sphereNormals usage:GL_STATIC_DRAW];
  
  //! 纹理
  self.vertextTextureCoordBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:(2* sizeof(GLfloat)) numberOfVertices:sizeof(sphereTexCoords)/(2*sizeof(GLfloat)) bytes:sphereTexCoords usage:GL_STATIC_DRAW];
  
  ///! 3. 处理纹理
  
  //! 地球纹理
  CGImageRef earthImageRef = [UIImage imageNamed:@"Earth512x256.jpg"].CGImage;
  ///! 纹理加载方式
  NSDictionary *earthOptions = @{
    GLKTextureLoaderOriginBottomLeft:[NSNumber numberWithBool:YES]
  };
  self.earchTextureInfo = [GLKTextureLoader textureWithCGImage:earthImageRef options:earthOptions error:NULL];
  
  //! 月亮纹理
  CGImageRef moonImageRef = [UIImage imageNamed:@"Moon256x128"].CGImage;
  NSDictionary *moonOptions = @{
    GLKTextureLoaderOriginBottomLeft:[NSNumber numberWithBool:YES]
  };
  self.moomTextureInfo = [GLKTextureLoader textureWithCGImage:moonImageRef options:moonOptions error:NULL];

  //!  将模型视图矩阵 加载到 self.baseEffect.transform.modelviewMatrix
  GLKMatrixStackLoadMatrix4(self.modelViewMatrixStack, self.baseEffect.transform.modelviewMatrix);
  
  ///! 初始化 在轨道上，月亮的位置
  self.moonRotationAngleDegress = -20.0f;
  
}

- (void)setClearColor:(GLKVector4)clearColorRGBA {
  glClearColor(clearColorRGBA.r, clearColorRGBA.g, clearColorRGBA.b, clearColorRGBA.a);
}

- (void)configureLight {
   
  ///! 1. 是否开启光照
  self.baseEffect.light0.enabled = GL_TRUE;
  
  //! 共用体/联合体 GLKVector4
   
  ///! 2. 设置 漫反射颜色
  self.baseEffect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
  
  /* 3. 世界坐标中 光 的坐标，这里光源是太阳
   * w=0.0 时，使用定向光公式计算光，向量X，Y，Z 来指定光的方向，光可以无限远，忽视其 衰减\聚光灯 属性
   * w!=0 时，指定坐标的光 在齐次坐标位置。 和光是一个点光源和聚光灯计算
   */
  self.baseEffect.light0.position = GLKVector4Make(1.0f, 0.0f, 0.8f, 0.0f);
  
  ///！ 4.光的环境
  self.baseEffect.light0.ambientColor = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);

  
}

#pragma mark - drawRect
//渲染场景
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  ///! 设置清屏颜色
  glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  
  ///! 计算地球的旋转角度
  _earthRotationAngleDegress += 360.0f/60.0f;
  ///！ 计算月亮的旋转角度。
  _moonRotationAngleDegress += (360.0f/60.0f)/SceneDaysPerMoonOrbit;
  
  /* 3. 准备绘制 封装的方法
   * 参数1: 用途，这里标记是 用于 顶点
   * 参数2: 数据读取个数
   * 参数3: 读取索引，起点
   * 参数4: 能否调用 glEnableVertexAttribArray(着色器是否读取的数据，是否启用了对应的属性决定， 允许shader去读取GPU数据)
   1. 默认下，出于性能考虑，着色器 属性是关闭的，这些数据在着色器中是不可见的，
   所以数据上传到GPU后，需要使用该函数，启用指定属性，才可以让顶点着色器访问属性数据
   
   glVertexAttribPointer ,只是建立CPU和GPU 之间的逻辑连接，从而实现CPU->GPU，但是GPU端能否对数据可见，取决于 glEnableVertexAttribArray 是否开启对应的属性。
   
   glEnableVertexAttribArray 函数只需要在 glDraw***() 函数 之前 调用即可。
   
   **/
  [self.vertexPositionBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
  
  ///! 光照数据
  [self.vertexNormalBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
  
  ///! 纹理数据
  [self.vertextTextureCoordBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:0 shouldEnable:YES];
  
  //! 3. 绘制
  [self drawEarth];
  [self drawMoon];
  
}

///! 绘制地球
- (void)drawEarth {
    
  ///! 获取纹理 name target
  self.baseEffect.texture2d0.name = self.earchTextureInfo.name;
  self.baseEffect.texture2d0.target = self.earchTextureInfo.target;
  
  /*
   当前的矩阵 应该如下
     1.0 0.0 0.0 0.0
     0.0 1.0 0.0 0.0
     0.0 0.0 1.0 0.0
     0.0 0.0 -5.0 1.0
     
     因为 在viewDidLoad中设置了
   1. 加载了一个单元矩阵
   2. z的负方向移动了 5.0
   
     //5.设置模型矩形 -5.0f表示往屏幕内移动-5.0f距离
     self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0f);
  */
  
  
  ///! 将当前的 modelviewMatrix 压栈
  GLKMatrixStackPush(self.modelViewMatrixStack);

  /* 在指定的轴上旋转 逻辑对应着 最上面的矩阵
   * 参数1: 结果矩阵
   * 参数2: 幅度
   * 参数3，4，5: 是否围绕 x y z 上旋转
   */
  GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(SceneEarthAxialTiltDeg), 1.0f, 0.0f, 0.0f);
  
  /* 矩阵相乘，得到当前矩阵，这是围绕X轴旋转之后的结果矩阵
   
   1.0 0.0 0.0 0.0
   0.0 0.917 0.398 0.0
   0.0 -0.398 0.917 0.0
   0.0 0.0 -5.0 1.0
   
   */
  self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);
  
  ///! 准备绘制
  [self.baseEffect prepareToDraw];
  
  
  /* 绘制
   * 类型： 三角形模型
   * 起点：0
   *
   */
  
  [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
  
  //！ 将 modelViewMatrixStack 出栈
  GLKMatrixStackPop(self.modelViewMatrixStack);

  /* 出栈后，当前矩阵为
       1.0 0.0 0.0 0.0
       0.0 1.0 0.0 0.0
       0.0 0.0 1.0 0.0
       0.0 0.0 -5.0 1.0
   */
  
  self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);

  
  
  
  
}

//! 绘制月亮
- (void)drawMoon {
  
  ///! 获取纹理 name target
  self.baseEffect.texture2d0.name = self.moomTextureInfo.name;
  self.baseEffect.texture2d0.target = self.moomTextureInfo.target;
  
  GLKMatrixStackPush(self.modelViewMatrixStack);

  //！ 自转->围绕Y轴转动
  GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(self.moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);

  //! 平移 -> 月球距离地球的距离，在Z轴的距离
  GLKMatrixStackTranslate(self.modelViewMatrixStack, 0.0f, 0.0f, SceneMoonDistanceFromEarth);

  ///! 缩放月亮，让月亮比地球小
  GLKMatrixStackScale(self.modelViewMatrixStack, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth);

  //! 公转 -> 以地球为中心，围绕Y轴转
  GLKMatrixStackRotate(self.modelViewMatrixStack, GLKMathDegreesToRadians(self.moonRotationAngleDegress), 0.0f, 1.0f, 0.0f);

  self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);

  [self.baseEffect prepareToDraw];

  //! sphereNumVerts 球体模型
  [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];

  GLKMatrixStackPop(self.modelViewMatrixStack);

  self.baseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.modelViewMatrixStack);

}

#pragma mark -Switch Click
//切换正投影效果或透视投影效果
- (IBAction)switchClick:(UISwitch *)sender {
  
  GLfloat aspect = self.view.bounds.size.width / self.view.bounds.size.height;
 
  if ([sender isOn]) {
    //正投影
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0 * aspect, 1.0 * aspect, -1.0, 1.0, 2.0, 120.0);

  } else {
    //透视投影
    self.baseEffect.transform.projectionMatrix = GLKMatrix4MakeFrustum(-1.0 * aspect, 1.0 * aspect, -1.0, 1.0, 2.0, 120.0);

  }
  
}

//横屏处理
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    
    return (toInterfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            toInterfaceOrientation !=
            UIInterfaceOrientationPortrait);
    
}

@end
