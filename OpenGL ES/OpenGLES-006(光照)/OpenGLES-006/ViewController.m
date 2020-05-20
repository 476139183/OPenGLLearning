//
//  ViewController.m
//  OpenGLES-006
//
//  Created by 段雨田 on 2020/5/12.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "sceneUtil.h"

@interface ViewController ()

@property (nonatomic, strong) EAGLContext *mContext;

//基本光照纹理
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
//额外光照纹理
@property (nonatomic, strong)GLKBaseEffect *extraEffect;
//顶点缓存区
@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *vertexBuffer;
//法线位置缓存区
@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *extraBuffer;

//是否 使用 平面法线
@property (nonatomic, assign) BOOL shouldUseFaceNormals;

//是否 绘制法线
@property (nonatomic, assign) BOOL shouldDrawNormals;

// 中心点的高
@property (nonatomic, assign) GLfloat centexVertexHeight;

@end

@implementation ViewController {
  //三角形-8面
  SceneTriangle triangles[NUM_FACES];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self setUp];

}

#pragma mark -- OpenGL ES
- (void)setUp {

  self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  GLKView *view = (GLKView *)self.view;
  
  view.context = self.mContext;
  
  view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  
  [EAGLContext setCurrentContext:self.mContext];
  
  ///! 初始化 Effect
  self.baseEffect = [[GLKBaseEffect alloc] init];
  self.baseEffect.light0.enabled = GL_TRUE;
  
  ///! 光的漫反射颜色
  self.baseEffect.light0.diffuseColor = GLKVector4Make(0.7f, 0.7f, 0.7f, 1.0f);
  
  ///! 世界坐标中，光的位置
  self.baseEffect.light0.position = GLKVector4Make(1.0f, 1.0f, 0.5f, 0.0f);
  
  //! 设置法线
  self.extraEffect = [[GLKBaseEffect alloc] init];
  self.extraEffect.useConstantColor = GL_TRUE;
  
  ///! 调整模型，倾斜,以便更好观察
  if (GL_TRUE) {
    ///! 围绕 X 轴 旋转 60 度
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-60.0f), 1.0f, 0.0f, 0.0f);
    
    ///! 再围绕 Z 轴 旋转 -30 度
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(-30.0f), 0.0f, 0.0f, 1.0f);
    
    ///! 再围绕Z轴移动 0.25
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 0.0f, 0.25f);
    
    ///!
    self.baseEffect.transform.modelviewMatrix = modelViewMatrix;
    self.extraEffect.transform.modelviewMatrix = modelViewMatrix;
  }
  
  ///! 设置 清屏颜色
  [self setClearColor:GLKVector4Make(0.0f, 0.0f, 0.0f, 1.0f)];
  
  ///! 确定 图形 的 8 个面
  triangles[0] = SceneTriangleMake(vertexA, vertexB, vertexD);
  triangles[1] = SceneTriangleMake(vertexB, vertexC, vertexF);
  triangles[2] = SceneTriangleMake(vertexD, vertexB, vertexE);
  triangles[3] = SceneTriangleMake(vertexE, vertexB, vertexF);
  triangles[4] = SceneTriangleMake(vertexD, vertexE, vertexH);
  triangles[5] = SceneTriangleMake(vertexE, vertexF, vertexH);
  triangles[6] = SceneTriangleMake(vertexG, vertexD, vertexH);
  triangles[7] = SceneTriangleMake(vertexH, vertexF, vertexI);
  
  ///! 先初始化 缓冲区
  /* 顶点缓冲区
   *
   *
   */
  self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles usage:GL_DYNAMIC_DRAW];
  
  ///! 先开辟，初始化，具体数据 后续计算
  self.extraBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SceneVertex) numberOfVertices:0 bytes:NULL usage:GL_DYNAMIC_DRAW];
  
  self.centexVertexHeight = 0.0f;
  ///! 是否使用 平面法向量
  self.shouldUseFaceNormals = YES;
  
}

- (void)setClearColor:(GLKVector4)clearColorRGBA {
    
  glClearColor(clearColorRGBA.r,
               clearColorRGBA.g,
               clearColorRGBA.b,
               clearColorRGBA.a);
  
}

#pragma mark -- GLKView DrawRect
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
  
  ///! 可以修改颜色
  [self setClearColor:GLKVector4Make(0.3f, 0.3f, 0.3f, 1.0f)];
  glClear(GL_COLOR_BUFFER_BIT);
  
  ///!
  [self.baseEffect prepareToDraw];
  
  ///! 准备绘制顶点数据
  [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:offsetof(SceneVertex,position) shouldEnable:YES];

  //! 准备绘制光照数据
  [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:offsetof(SceneVertex, normal) shouldEnable:YES];
  
  ///! 绘制 三角形
  [self.vertexBuffer drawArrayWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sizeof(triangles)/sizeof(SceneVertex)];
  
  if (self.shouldDrawNormals) {
    [self drawNormals];
  }
  
}


//! 绘制法线
- (void)drawNormals {
    
  ///！绘制法线
  GLKVector3 normalLineVerteices[NUM_LINE_VERTS];
  
  /* 以 每一个顶点的坐标为起点，顶点坐标上的法向量作为终点
   
   
   
   */
  SceneTrianglesNormalLinesUpdate(triangles, GLKVector3MakeWithArray(self.baseEffect.light0.position.v), normalLineVerteices);
  
  
  ///！ 重新开辟空间
  [self.extraBuffer reinitWithAttribStride:sizeof(GLKVector3) numberOfVertices:NUM_LINE_VERTS bytes:normalLineVerteices];
  
  //! 准备绘制数据
  [self.extraBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
  
  ///! 指定 使用颜色,用绿色将顶点法线绘制出来
  self.extraEffect.useConstantColor = GL_TRUE;
  self.extraEffect.constantColor = GLKVector4Make(0.0f, 1.0f, 0.0f,1.0f);
  
  ///! 准备绘制
  [self.extraEffect prepareToDraw];
  
  //! 开始绘制 线段
  [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:0 numberOfVertices:NUM_NORMAL_LINE_VERTS];
  
  ///! 绘制 黄色光源
  self.extraEffect.constantColor = GLKVector4Make(1.0f, 1.0f, 0.0f, 1.0f);
  [self.extraEffect prepareToDraw];
  
  [self.extraBuffer drawArrayWithMode:GL_LINES startVertexIndex:NUM_NORMAL_LINE_VERTS numberOfVertices:(NUM_LINE_VERTS - NUM_NORMAL_LINE_VERTS)];
  
  
}

//! 更新法向量
- (void)updateNormals {
    
  if (self.shouldUseFaceNormals) {
    //! 如果可以使用 平面法线，那么可以更新每一个点的平面法向量
    SceneTrianglesUpdateFaceNormals(triangles);
  } else {
    ///! 否则 计算平均值 更新顶点法向量
    SceneTrianglesUpdateVertexNormals(triangles);
  }
  
  [self.vertexBuffer reinitWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(triangles)/sizeof(SceneVertex) bytes:triangles];

}

#pragma mark --Set
- (void)setCentexVertexHeight:(GLfloat)centexVertexHeight {
   
  _centexVertexHeight = centexVertexHeight;
  
    //! 更新顶点 E
  SceneVertex newVertexE = vertexE;
  newVertexE.position.z = _centexVertexHeight;
  
  ///! 修改 与 顶点E 相关 的三角形的数据
  triangles[2] = SceneTriangleMake(vertexD, vertexB, newVertexE);
  triangles[3] = SceneTriangleMake(newVertexE, vertexB, vertexF);
  triangles[4] = SceneTriangleMake(vertexD, newVertexE, vertexH);
  triangles[5] = SceneTriangleMake(newVertexE, vertexF, vertexH);
  
  ///! 更新法线
  [self updateNormals];

}

- (void)setShouldUseFaceNormals:(BOOL)shouldUseFaceNormals {
   
  if (shouldUseFaceNormals != _shouldUseFaceNormals) {
    _shouldUseFaceNormals = shouldUseFaceNormals;
    [self updateNormals];
  }
}

#pragma makr --UI Change

- (IBAction)takeShouldDrawNormals:(UISwitch *)sender {
  self.shouldDrawNormals = sender.isOn;
  
}

///！ 是否使用 平面法向量
- (IBAction)takeShouldUseFaceNormals:(UISwitch *)sender {
  self.shouldUseFaceNormals = sender.isOn;
}

//改变Z的高度
- (IBAction)changeCenterVertexHeight:(UISlider *)sender {
  self.centexVertexHeight = sender.value;
}


@end
