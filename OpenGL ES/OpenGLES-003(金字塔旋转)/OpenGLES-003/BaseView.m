//
//  BaseView.m
//  OpenGLES-003
//
//  Created by 段雨田 on 2020/5/9.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "BaseView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

@interface BaseView ()

///! 图层
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, strong) EAGLContext *myContext;

@property (nonatomic, assign) GLuint myColorRenderBuffer;

@property (nonatomic, assign) GLuint myColorFramBuffer;

//!
@property (nonatomic, assign) GLuint myProgram;
//! 顶点标记
@property (nonatomic, assign) GLuint myVertices;


@end

@implementation BaseView {
  ///! 围绕 X、Y、Z 旋转的度数
  float xDegree;
  float yDegree;
  float zDegree;

  ///! 标记 是否在 X、Y、Z 轴旋转
  BOOL bX;
  BOOL bY;
  BOOL bZ;

  //! 定时器
  NSTimer *myTimer;
  
  
}


+ (Class)layerClass {
  return [CAEAGLLayer class];
}


- (IBAction)XClick:(id)sender {
  
  ///! 开启定时器
  
  if (myTimer == nil) {
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
  }
  
  bX = !bX;
  
}

- (IBAction)YClick:(id)sender {
  
  ///! 开启定时器
   
  if (myTimer == nil) {
    
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
   
  }
   
   
  bY = !bY;
  
}

- (IBAction)ZClick:(id)sender {
  
 
  ///! 开启定时器
  
  if (myTimer == nil) {
    
    myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
  
  }
   
  bZ = !bZ;
}

- (void)reDegree {
  
  xDegree += bX * 5;
  
  yDegree += bY * 5;

  zDegree += bZ * 5;

  
  //! 重新渲染
  [self render];
  
  
}


#pragma mark - setupRC
- (void)layoutSubviews {
  
  
  //1.设置图层
  [self setupLayer];
     
  //2.设置上下文
  [self setupContext];
     
  //3.清空缓存区
  [self deleteBuffer];
     
  //4.设置renderBuffer;
  [self setupRenderBuffer];
    
  //5.设置frameBuffer
  [self setupFrameBuffer];
    
  //6.绘制
  [self render];
  

}

- (void)setupLayer {
  ///! 参考 002
  self.myEagLayer = (CAEAGLLayer *)self.layer;
  
  //! 比例因子
  [self setContentScaleFactor:[UIScreen mainScreen].scale];
  
  
  self.myEagLayer.opaque = YES;
  
  self.myEagLayer.drawableProperties = @{
    kEAGLDrawablePropertyRetainedBacking : [NSNumber numberWithBool:false],
    kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
  };
  

}

- (void)setupContext {
  
  self.myContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  if (_myContext == nil) {
    NSLog(@"创建上下文失败");
    return;
  }
  
  if ([EAGLContext setCurrentContext:self.myContext] == NO) {
    NSLog(@"设置当前上下文失败");
    return;
  }
  
  
  
}

- (void)deleteBuffer {
  
  glDeleteBuffers(1, &_myColorRenderBuffer);
  _myColorFramBuffer = 0;
  
  glDeleteBuffers(1, &_myColorFramBuffer);
  _myColorFramBuffer = 0;
  
}

- (void)setupRenderBuffer {
  
  GLuint buffer;
  
  ///! 1. 申请缓冲区标记
  glGenRenderbuffers(1, &buffer);
  self.myColorRenderBuffer = buffer;
  ///! 2. 绑定缓冲区，告诉程序，这个缓冲区是干嘛的
  glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
  
  //! 3. 分配空间,从 GL_RENDERBUFFER 分配到 self.myEagLayer
  [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
  
  
  
  
}

- (void)setupFrameBuffer {
 
  // 1.
  GLuint buffer;

  //2.
  glGenFramebuffers(1, &buffer);
  self.myColorFramBuffer = buffer;
  
  // 3.
  glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFramBuffer);
  
  ///! 和 上面不一样， FramBuffer 是一个管理者，所以不需要分配空间
  /*
   * GL_FRAMEBUFFER 和上面对应
   * 附着点叫 GL_COLOR_ATTACHMENT0
   *
   * 对应的是 GL_RENDERBUFFER 类型， 数据是 self.myColorFramBuffer
   */
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorFramBuffer);
  
  
}

- (void)render {
  
  ///！ 准备好 GLSL 文件，
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  
  ///! 设置视口
  
  CGFloat scale = [UIScreen mainScreen].scale;
  
  glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
  
  ///! 文件读取
  NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
  
  NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];

  //! 创建 程序
  if (self.myProgram) {
    glDeleteProgram(self.myProgram);
    self.myProgram = 0;
  }
  
  self.myProgram = [self loadShader:vertFile frag:fragFile];
  
  
  //! 链接
  glLinkProgram(self.myProgram);
  
  GLint linkSuccess;
  
  //获取链接状态
  glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
  
  if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"error%@", messageString);
    return ;
  } else {
    glUseProgram(self.myProgram);
  }
  
  ///---------------------------------------------
  
  //! 创建索引数组
  GLuint indices[] = {
        
    0, 3, 2,
    0, 1, 3,
    0, 2, 4,
    0, 4, 1,
    2, 3, 4,
    1, 4, 3,
    
  };
  
  //判断顶点缓存区是否为空，如果为空则申请一个缓存区标识符
  if (self.myVertices == 0) {
    glGenBuffers(1, &_myVertices);
  }
  
  ///! 顶点数据
  //前3顶点值（x,y,z），后3位颜色值(RGB)
    
  GLfloat attrArr[] = {
       
    -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
        
    0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
        
    -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
       
    0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
        
    0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
     
  };
  
  
  ///! 处理顶点数据:
  glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
  
  ///！ 从 CPU 拷贝到 GPU
  glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);

  ///！ 从入口 传到 顶点 position
  GLuint position = glGetAttribLocation(self.myProgram, "position");
  
  glEnableVertexAttribArray(position);

  ///! 设置读取方式
  glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6,(GLfloat *)NULL+ 0);
  
  ///! 处理颜色值
  GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
  
  glEnableVertexAttribArray(positionColor);

  glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6,(GLfloat *)NULL+ 3);


  
  //! 投影矩阵
  GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
  
  GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
  
  
  float width = self.frame.size.width;
  float height = self.frame.size.height;
  
  //! 创建 4 * 4 矩阵
  KSMatrix4 _projectionMatrix;
  
  ///! 加载单元矩阵
  ksMatrixLoadIdentity(&_projectionMatrix);
  
  //! 纵横比
  float aspect = width / height;
  
  ///! 透视投影矩阵
  /* 结果矩阵：_projectionMatrix
   * 相机角度：30.0f
   * 纵横比
   * 近裁剪面：5.0f
   * 远裁剪面：20.0f
   */
  ksPerspective(&_projectionMatrix, 30.0f, aspect, 5.0f, 20.0f);
  
  ///！ 将矩阵传递到 着色器中 ，这里表示第0行 第0列 开始传递
  glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
  
  ///! 开启 背面剔除
  glEnable(GL_CULL_FACE);
  
  
  ///! 模型视图矩阵
  KSMatrix4 _modeMatrix;
  ksMatrixLoadIdentity(&_modeMatrix);

  ///! 平移 - z轴负10
  ksTranslate(&_modeMatrix, 0.0f, 0.0f, -10.0f);
  
  
  ///! 旋转矩阵
  KSMatrix4 _rotationMatrix;
  ksMatrixLoadIdentity(&_rotationMatrix);

  
  ///! 围绕 X 轴
  ksRotate(&_rotationMatrix, xDegree, 1.0f, 0.0f, 0.0f);
  
  
  ///! 围绕 Y 轴
  ksRotate(&_rotationMatrix, yDegree, 0.0f, 1.0f, 0.0f);
  
  ///! 围绕 X 轴
  ksRotate(&_rotationMatrix, zDegree, 0.0f, 0.0f, 1.0f);
  
  
  ///! 矩阵相乘- 得到最终的结果矩阵
  
  ksMatrixMultiply(&_modeMatrix, &_rotationMatrix, &_modeMatrix);
  
  //! 将模型视图 传递到 Uniform 里面
  
  glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modeMatrix.m[0][0]);

  
  /* 索引绘图
   * 模式： GL_TRIANGLES
   * 个数：
   * 类型
   * 索引：
   */
  glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_INT, indices);
  
  [self.myContext presentRenderbuffer:GL_RENDERBUFFER];

  
  
}

#pragma mark -- Shader
- (GLuint)loadShader:(NSString *)vert frag:(NSString *)frag {
    //创建2个临时的变量，verShader,fragShader
    GLuint verShader,fragShader;
    //创建一个Program
    GLuint program = glCreateProgram();
    //编译文件
    //编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteProgram(verShader);
    glDeleteProgram(fragShader);
    
    return program;
}

////链接shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    //读取文件路径字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    //获取文件路径字符串，C语言字符串
    const GLchar *source = (GLchar *)[content UTF8String];
    
    //创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //将顶点着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //把着色器源代码编译成目标代码
    glCompileShader(*shader);

}


@end
