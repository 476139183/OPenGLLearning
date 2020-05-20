//
//  GLView.m
//  OpenGLES-010
//
//  Created by 段雨田 on 2020/5/18.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "GLView.h"
@import OpenGLES;

//! 顶点结构体
typedef struct {
  float position[4]; //顶点x,y,z,w
  float textureCoordinate[2]; //纹理 s,t
} CustomVertex;

//! 属性枚举
enum {
  ATTRIBUTE_POSITION = 0, //属性_顶点
  ATTRIBUTE_INPUT_TEXTURE_COORDINATE, //属性_输入纹理坐标
  TEMP_ATTRIBUTE_POSITION, //色温_属性_顶点位置
  TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE, //色温_属性_输入纹理坐标
  NUM_ATTRIBUTES //属性个数
};

//! 属性数组
GLint glViewAttributes[NUM_ATTRIBUTES];

enum {
  UNIFORM_INPUT_IMAGE_TEXTURE = 0, //输入纹理
  TEMP_UNIFORM_INPUT_IMAGE_TEXTURE, //色温_输入纹理
  UNIFORM_TEMPERATURE, //色温
  UNIFORM_SATURATION, //饱和度
  NUM_UNIFORMS //Uniforms个数
};

//! Uniforms数组
GLint glViewUniforms[NUM_UNIFORMS];

@implementation GLView

#pragma mark - Life Cycle
- (void)dealloc {
  if (_colorTempFramebuffer) {
    glDeleteFramebuffers(1, &_colorTempFramebuffer);
    _colorTempFramebuffer = 0;
  }
   
  if (_colorTempRenderbuffer) {
    glDeleteRenderbuffers(1, &_colorTempRenderbuffer);
    _colorTempRenderbuffer = 0;
  }
   
  if (_saturatedFramebuffer) {
    glDeleteFramebuffers(1, &_saturatedFramebuffer);
    _saturatedFramebuffer = 0;
  }
  
  if (_saturatedRenderBuffer) {
     glDeleteFramebuffers(1, &_saturatedRenderBuffer);
    _saturatedRenderBuffer = 0;
  }
  
  _context = nil;
}

#pragma mark - Override
// 想要显示 OpenGL 的内容, 需要把它缺省的 layer 设置为一个特殊的 layer(CAEAGLLayer).
+ (Class)layerClass {
  return [CAEAGLLayer class];
}

#pragma mark - Setup
- (void)setup {
  
  //! 1.设置 饱和度/色温
  [self setupData];
  //！2.设置图层
  [self setupLayer];
  //! 3 设置图形上下文
  [self setupContext];
  //!4.设置renderBuffer
  [self setupRenderBuffer];
  //! 5. 设置 frameBuffer
  [self setupFrameBuffer];
  //! 6. 检查 frameBuffer
  NSError *error;
  NSAssert1([self checkFramebuffer:&error], @"%@", error.userInfo[@"ErrorMessage"]);
   
  //!7. 链接 色温shader
  [self compileTemperatureShaders];
  // 8. 链接  饱和度 shader
  [self compileSaturationShaders];
  //！9. 设置 VBO
  [self setupVBOs];
  //！ 10 设置纹理
  [self setupTemp];
}

//设置色温\饱和度初始值
- (void)setupData {
  
  _temperature = 0.5;
  _saturation = 0.5;
  
}

//设置图层
- (void)setupLayer {
    
  _eaglLayer = (CAEAGLLayer *)self.layer;
  _eaglLayer.opaque = YES;
}


//设置图形上下文
- (void)setupContext {
  if (!_context) {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  }
  
  NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
    
}

//设置RenderBuffer
- (void)setupRenderBuffer {
    
  if (_colorTempRenderbuffer) {
    glDeleteRenderbuffers(1, &_colorTempRenderbuffer);
    _colorTempRenderbuffer = 0;
  }
  // 生成renderbuffer ( renderbuffer = 用于展示的窗口 )
  glGenRenderbuffers(1, &_colorTempRenderbuffer);
   // 绑定renderbuffer
  glBindRenderbuffer(GL_RENDERBUFFER, _colorTempRenderbuffer);
  // GL_RENDERBUFFER 的内容存储到实现 EAGLDrawable 协议的 CAEAGLLayer
  [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
  
}

//设置FrameBuffer
- (void)setupFrameBuffer {
  if (_colorTempFramebuffer) {
    glDeleteFramebuffers(1, &_colorTempFramebuffer);
    _colorTempFramebuffer = 0;
  }
  // 生成 framebuffer ( framebuffer = 画布 )
  glGenFramebuffers(1, &_colorTempFramebuffer);
  // 绑定 fraembuffer
  glBindFramebuffer(GL_FRAMEBUFFER, _colorTempFramebuffer);
  // framebuffer 不对绘制的内容做存储,
  //所以这一步是将 framebuffer 绑定到 renderbuffer ( 绘制的结果就存在 renderbuffer )
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorTempRenderbuffer);
  
}

- (void)setupVBOs {
  
  //顶点坐标和纹理坐标
  static const CustomVertex vertices[] =
  {
    { .position = { -1.0, -1.0, 0, 1 }, .textureCoordinate = { 0.0, 0.0 } },
    { .position = {  1.0, -1.0, 0, 1 }, .textureCoordinate = { 1.0, 0.0 } },
    { .position = { -1.0,  1.0, 0, 1 }, .textureCoordinate = { 0.0, 1.0 } },
    { .position = {  1.0,  1.0, 0, 1 }, .textureCoordinate = { 1.0, 1.0 } }
  };
  
  //初始化缓存区
  //创建VBO的3个步骤
  //1.生成新缓存对象glGenBuffers
  //2.绑定缓存对象glBindBuffer
  //3.将顶点数据拷贝到缓存对象中glBufferData
  
  //！ 初始化缓冲区
  GLuint vertexBuffer;
  
  glGenBuffers(1, &vertexBuffer);
  
  glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
  
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
  
  
}


- (void)setupTemp {
  
  //申请_tempFramesBuffe标记
  glGenFramebuffers(1, &_saturatedFramebuffer);
     
  //绑定纹理之前,激活纹理
  glActiveTexture(GL_TEXTURE0);
     
  //申请纹理标记
  glGenTextures(1, &_saturatedTexture);
    
  //绑定纹理
  glBindTexture(GL_TEXTURE_2D, _saturatedTexture);
     
  //将图片载入纹理
  /*
      
   glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels)
      
   参数列表:
     
   1.target,目标纹理
   2.level,一般设置为0
   3.internalformat,纹理中颜色组件
   4.width,纹理图像的宽度
   5.height,纹理图像的高度
   6.border,边框的宽度
   7.format,像素数据的颜色格式
   8.type,像素数据数据类型
   9.pixels,内存中指向图像数据的指针
     
   */
      
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
     
  //设置纹理参数
  //放大\缩小过滤
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      
  //绑定FrameBuffer
  glBindFramebuffer(GL_FRAMEBUFFER, _saturatedFramebuffer);
      
      
  /* 应用FBO渲染到纹理（glGenTextures），直接绘制到纹理中。
   glCopyTexImage2D 是渲染到FrameBuffer->复制FrameBuffer中的像素产生纹理。
   glFramebufferTexture2D 直接渲染生成纹理，做全屏渲染（比如全屏模糊）时 比glCopyTexImage2D高效的多。
  */

 
  /*
   glFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level)
   参数列表:
   1.target,GL_FRAMEBUFFER
   2.attachment,附着点名称
   3.textarget,GL_TEXTURE_2D
   4.texture,纹理对象
   5.level,一般为0
   */
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _saturatedTexture, 0);
  
}
  

#pragma mark - Private
- (BOOL)checkFramebuffer:(NSError *__autoreleasing *)error {
  
  //! 检查
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  
  NSString *errorMessage = nil;
  
  BOOL result = NO;
  
  switch (status) {
    case GL_FRAMEBUFFER_UNSUPPORTED:
      errorMessage = @"framgeBuffer 不支持该格式";
      result = NO;
      break;
    case GL_FRAMEBUFFER_COMPLETE:
      errorMessage = @"framgeBuffer 创建成功！";
      result = YES;
      break;
     
    case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
      errorMessage = @"framgeBuffer 不完整，缺少组件";
      result = NO;
      break;
     
    case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
      errorMessage = @"framgeBuffer 附加图片必须指定大小";
      result = NO;
      break;
    default:
      errorMessage = @"其他未收录的错误";
      result = NO;
      break;
  }
   
  NSLog(@"%@",errorMessage ? errorMessage : @"");
  *error = errorMessage ? [NSError errorWithDomain:@"com.Yue.error"
                                              code:status
                                          userInfo:@{@"ErrorMessage" : errorMessage}] : nil;
  return result;
}

///! 初始化着色器
- (GLuint)compileShader:(NSString *)shaderName
               withType:(GLenum)shaderType {
   
  //! 获取路径
  NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
  
  NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:nil];
  
  if (!shaderString) {
    NSLog(@"路径错误!");
    exit(0);
  }
  
  //！创建临时shader
  GLuint shaderHandle = glCreateShader(shaderType);
  
  //! 获取shader路径
  const char *shaderStringUFT8 = [shaderString UTF8String];
  
  int shaderStringLength = (int)[shaderString length];
  //! 传入长度，也可以不传，
  glShaderSource(shaderHandle, 1, &shaderStringUFT8, &shaderStringLength);
  
  //! 编译
  glCompileShader(shaderHandle);
  
  //! 获取编译状态
  GLint compileSuccess;
  
  //获取编译信息
  glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
  
  //打印编译时出错信息
  if (compileSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"初始化着色器: %@", messageString);
    exit(1);
  }
  
  return shaderHandle;
}

//！色温处理shaders编译（顶点着色器+色温片元着色器）
- (void)compileTemperatureShaders {
    
  //! 1. 获取 vertex shader 路径
  GLuint vertexShader = [self compileShader:@"MyVertexShader.vsh" withType:GL_VERTEX_SHADER];
  
  //! 2. fragment shader
  GLuint fragmentShader = [self compileShader:@"MyTemperature.fsh" withType:GL_FRAGMENT_SHADER];
    
  //! 创建 色温的 program
  _colorTempProgramHandle = glCreateProgram();
  
  //! 附着
  glAttachShader(_colorTempProgramHandle, vertexShader);
  glAttachShader(_colorTempProgramHandle, fragmentShader);
  
  //! 链接
  glLinkProgram(_colorTempProgramHandle);
  
  //! 获取link状态
  GLint linkSuccess;
  
  glGetProgramiv(_colorTempProgramHandle, GL_LINK_STATUS, &linkSuccess);
  
  //链接失败处理
   if (linkSuccess == GL_FALSE) {
     GLchar messages[256];
     glGetShaderInfoLog(_colorTempProgramHandle, sizeof(messages), 0, &messages[0]);
     NSString *messageString = [NSString stringWithUTF8String:messages];
     NSLog(@"链接着色器: %@", messageString);
     exit(1);
   }
  
  //! 使用
  glUseProgram(_colorTempProgramHandle);
  
  //! 顶点着色器 的  顶点坐标
  glViewAttributes[ATTRIBUTE_POSITION] = glGetAttribLocation(_colorTempProgramHandle, "position");
  
  //! 顶点着色器 的 纹理坐标
  glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE] = glGetAttribLocation(_colorTempProgramHandle, "inputTextureCoordinate");
  
  ///! 绑定 片元 着色器的纹理 inputImageTexture
  glViewUniforms[UNIFORM_INPUT_IMAGE_TEXTURE] = glGetUniformLocation(_colorTempProgramHandle, "inputImageTexture");
  
  //！ 色温值
  glViewUniforms[UNIFORM_TEMPERATURE] = glGetUniformLocation(_colorTempProgramHandle, "temperature");
  
  //! 打开数据可读属性,只 针对 Attribute（属性）
  glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]);
  glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);

}

//！饱和度
- (void)compileSaturationShaders {
    
  //!  获取路径-顶点着色器 共用
  GLuint vertexShader = [self compileShader:@"MyVertexShader.vsh" withType:GL_VERTEX_SHADER];
  //! 饱和度片元着色器
  GLuint fragmentShader = [self compileShader:@"MySaturation.fsh" withType:GL_FRAGMENT_SHADER];
  
  //! 创建饱和度program
  _saturatedProgramHandle = glCreateProgram();
  
  glAttachShader(_saturatedProgramHandle, vertexShader);
  glAttachShader(_saturatedProgramHandle, fragmentShader);
  
  glLinkProgram(_saturatedProgramHandle);
  
  //获取link状态
  GLint linkSuccess;
  glGetProgramiv(_saturatedProgramHandle, GL_LINK_STATUS, &linkSuccess);
     
    
  //link失败处理
  if (linkSuccess == GL_FALSE) {
    GLchar messages[256];
    glGetShaderInfoLog(_saturatedProgramHandle, sizeof(messages), 0, &messages[0]);
    NSString *messageString = [NSString stringWithUTF8String:messages];
    NSLog(@"链接着色器: %@", messageString);
    exit(1);
  }
     
  //! 使用
  glUseProgram(_saturatedProgramHandle);

  //！顶点坐标 属性
  glViewAttributes[TEMP_ATTRIBUTE_POSITION] = glGetAttribLocation(_saturatedProgramHandle, "position");

  //！ 纹理坐标 属性
  glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]  = glGetAttribLocation(_saturatedProgramHandle, "inputTextureCoordinate");

  //！纹理
  glViewUniforms[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE] = glGetUniformLocation(_saturatedProgramHandle, "inputImageTexture");

  ///! 饱和度
  glViewUniforms[UNIFORM_SATURATION] = glGetUniformLocation(_saturatedProgramHandle, "saturation");

  glEnableVertexAttribArray(glViewAttributes[TEMP_ATTRIBUTE_POSITION]);
  glEnableVertexAttribArray(glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);

  
  
}

- (void)render {
  
  //！ 绘制第一个滤镜,使用 饱和度程序
  glUseProgram(_saturatedProgramHandle);
    
  //! 绑定缓冲区
  glBindFramebuffer(GL_FRAMEBUFFER, _saturatedFramebuffer);
  
  //! 设置视口
  glViewport(0, 0, self.frame.size.width *  self.contentScaleFactor, self.frame.size.height *  self.contentScaleFactor);
  
  glClearColor(0, 0, 1, 1);
  
  glClear(GL_COLOR_BUFFER_BIT);
  
  //! 传递给数据
  glUniform1i(glViewUniforms[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE], 1);
  glUniform1f(glViewUniforms[UNIFORM_SATURATION], _saturation);
  
  //! 顶点数据 数据来源->VBO vertices
  glVertexAttribPointer(glViewAttributes[TEMP_ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
  
  /* 纹理坐标 数据来源->VBO vertices
   *
   */
  glVertexAttribPointer(glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(sizeof(float)*4));
    
  
  //!  开始绘制
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
  
  //! 绘制第二个滤镜，色温滤镜
  glUseProgram(_colorTempProgramHandle);
  
  glBindFramebuffer(GL_FRAMEBUFFER, _colorTempFramebuffer);
  //! rendbuffer
  glBindRenderbuffer(GL_RENDERBUFFER, _colorTempRenderbuffer);

  //设置清屏颜色
  glClearColor(1, 0, 0, 1);
  
  //清除颜色缓存区
  glClear(GL_COLOR_BUFFER_BIT);
  
  //设置视口
   
  glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);
  
  //为当前的program指定uniform值
     
  /*
   glUniform1i (GLint location, GLint x)
   参数列表:
   1.location,位置
   2.value,值
   */
    
  //纹理
  glUniform1i(glViewUniforms[UNIFORM_INPUT_IMAGE_TEXTURE], 0);
     
  //色温
  glUniform1f(glViewUniforms[UNIFORM_TEMPERATURE], _temperature);
    
  /*
     
   void glVertexAttribPointer( GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride,const GLvoid * pointer);
   从CPU内存中把数据传递到GPU中
   参数列表:
   1.index,索引值
   2.size,组件属性
   3.type,类型
   4.normalied,是否归一化
   5.stride,偏移量,步长
   6.pointer,指针位置
   */
    
  //顶点数据
  glVertexAttribPointer(glViewAttributes[ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
     
  //纹理数据
  glVertexAttribPointer(glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(sizeof(float) * 4));
     
  //绘制
    
  /*
     
   glDrawArrays (GLenum mode, GLint first, GLsizei count);
   参数列表:
   1.mode,模式
   2.first,从数组的哪一位开始绘制,一般设置为0
   3.count,顶点个数
   */
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
     
  //! 要求本地窗口系统显示OpenGL ES渲染缓存绑定到RenderBuffer上
  [_context presentRenderbuffer:GL_RENDERBUFFER];
  
}

#pragma mark - Public
- (void)layoutGLViewWithImage:(UIImage *)image {
   
  //1. 设置
  [self setup];
  //2. 设置纹理图片
  [self setupTextureWithImage:image];
  //3. 渲染
  [self render];
}

//设置色温
- (void)setTemperature:(CGFloat)temperature {
  //！ 更新色温
  _temperature = temperature;
  //! 重新渲染
  [self render];
  
}

//设置饱和度
- (void)setSaturation:(CGFloat)saturation {
  _saturation = saturation;
  [self render];
}

//设置纹理图片
- (void)setupTextureWithImage:(UIImage *)image {
    
  //! 获取图片的宽/高
  size_t width = CGImageGetWidth(image.CGImage);
  size_t height = CGImageGetHeight(image.CGImage);
  
  //! 创建上下文的颜色组件
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  //! 计算图片数据大小->开辟空间
  void *imageData = malloc(width*height*4);
  

  /* 4. 创建位图
   * data:指向要渲染的数据内存地址
   * width：位图的宽度 单位像素
   * height:位图的高度 单位像素
   * bitsPerComponent 颜色空间位数，8位
   * bytePerRow 位图一行的所占的内存空间
   * space 颜色空间(当前上下午的颜色空间)
   * bitmapInfo 指定位图是否包含透明通道
   */
  CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, 4*width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  
  //! 创建 上下文之后，释放 colorSpace
  CGColorSpaceRelease(colorSpace);
  
  /*
   * c 要绘制矩阵的图形上下文
   * rect 矩形
   */
  CGContextClearRect(context, CGRectMake(0, 0, width, height));
  
  
  /* CTM : 用户空间 转换到 设备空间
   *
   */
  CGContextTranslateCTM(context, 0, height);
  //！ 坐标不一样，所以要进行翻转
  CGContextScaleCTM(context, 1.0f, -1.0f);
  
  //! 绘制图片
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
  
  //! 释放
  CGContextRelease(context);
  
  //! 绑定纹理 GL_TEXTURE0 和 GL_TEXTURE1 没区别
  glActiveTexture(GL_TEXTURE1);
  
  //! 生成纹理标记
  glGenTextures(1, &_colorTempTexture);
  
  //! 绑定纹理
  glBindTexture(GL_TEXTURE_2D, _colorTempTexture);
  
  //! 设置纹理
  //! 环绕方式
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  //! 放大缩小过滤器:都改为线性过滤
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);


  /*! 将图片载入纹理
      1.target,目标纹理
      2.level,一般设置为0
      3.internalformat,纹理中颜色组件
      4.width,纹理图像的宽度
      5.height,纹理图像的高度
      6.border,边框的宽度
      7.format,像素数据的颜色格式
      8.type,像素数据数据类型
      9.pixels,内存中指向图像数据的指针
   */
  glTexImage2D(GL_TEXTURE_2D,
               0,
               GL_RGBA,
               (GLint)width,
               (GLint)height,
               0,
               GL_RGBA,
               GL_UNSIGNED_BYTE,
               imageData);
  
  
  //! 释放
  free(imageData);

  
}


@end
