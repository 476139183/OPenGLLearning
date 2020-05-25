//
//  BaseView.m
//  OpenGLES-002
//
//  Created by 段雨田 on 2020/5/7.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "BaseView.h"
#import <OpenGLES/ES2/gl.h>
/*
 不采用 GLBaseEffect,使用编译链接自定义shader，用简单的GLSL 语言，来实现顶点着色器\片元着色器，并实现图形的简单变换
 
 思路：
 1. 创建图层
 2. 创建上下文
 3. 清空缓冲区
 4. 设置RenderBuffer，FrameBuffer
 5. 开始绘制
 
 
 */

@interface BaseView ()

@property (nonatomic, strong) CAEAGLLayer *myEagLayer;

@property (nonatomic, strong) EAGLContext *myContext;

///! 颜色 渲染缓冲区
@property (nonatomic, assign) GLuint myColorRenderBuffer;
///！颜色 帧缓冲区
@property (nonatomic, assign) GLuint myColorFrameBuffer;

///!
@property (nonatomic, assign) GLuint myPrograme;

@end

@implementation BaseView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (void)layoutSubviews {

  //1.设置图层
  [self setupLayer];
  //2.设置图形上下文
  [self setupContext];
  //3.清空缓存区
  [self deleteRenderAndFrameBuffer];
  //4.设置RenderBuffer
  [self setupRenderBuffer];
  //5.设置FrameBuffer
  [self setupFrameBuffer];
  //6.开始绘制
  [self renderLayer];
  
  
}

- (void)setupLayer {
  
  ///! 设置图层
  self.myEagLayer = (CAEAGLLayer *)self.layer;
  
  //! 设置比例因子 2倍 还是 3倍
  [self setContentScaleFactor:[UIScreen mainScreen].scale];
  
  ///! 设置透明度 默认是NO 透明的
  self.myEagLayer.opaque = YES;
  
  /*! 设置描述属性
   * kEAGLDrawablePropertyRetainedBacking : 绘制之后，是否保留其内容。 我们选择 false
   * kEAGLDrawablePropertyColorFormat : 绘制对象 内部的颜色缓冲区格式，我们选择的是 RGBA * 8 = 32位
   */
  self.myEagLayer.drawableProperties = @{
    kEAGLDrawablePropertyRetainedBacking : [NSNumber numberWithBool:false],
    kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
  };
  
  
}

- (void)setupContext {
  
  //！ 指定API
  EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
  
  ///! 创建图形上下文
  _myContext = [[EAGLContext alloc] initWithAPI:api];
  
  ///! 判断
  if (_myContext == NULL) {
    NSLog(@"创建失败");
    return;
  }
  
  ///! 设置图形上下文
  if (![EAGLContext setCurrentContext:_myContext]) {
    NSLog(@"设置图形上下文失败");
    return;
  }
  
  
}

- (void)deleteRenderAndFrameBuffer {
  /*
    buffer分为frame buffer 和 render buffer2个大类。
   
   1. frame buffer 相当于 render buffer的管理者。frame buffer object即称FBO，常用于离屏渲染缓存等。
   
   2. renderbuffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。//! 颜色缓冲区，深度缓冲区，模版缓冲区

   常用函数：
      //绑定buffer标识符
      glGenRenderbuffers(<#GLsizei n#>, <#GLuint *renderbuffers#>)
      glGenFramebuffers(<#GLsizei n#>, <#GLuint *framebuffers#>)
   
     //绑定空间
     glBindBuffer(<#GLenum target#>, <#GLuint buffer#>)
     glBindRenderbuffer(<#GLenum target#>, <#GLuint renderbuffer#>)
     glGenFramebuffers(<#GLsizei n#>, <#GLuint *framebuffers#>)
   
     //！删除缓冲空间
     glDeleteBuffers(<#GLsizei n#>, <#const GLuint *buffers#>)
   
   */
  
  glDeleteBuffers(1, &_myColorRenderBuffer);
  self.myColorRenderBuffer = 0;
   
  glDeleteBuffers(1, &_myColorFrameBuffer);
  self.myColorFrameBuffer = 0;
}

- (void)setupRenderBuffer {
  
  //! 定义缓冲区
  GLuint buffer;
  
  /// 申请一个缓冲区标记
  glGenRenderbuffers(1, &buffer);
  
  self.myColorRenderBuffer = buffer;
  
  ///! 将标记符 绑定到指定的缓冲区GL_RENDERBUFFER
  glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
  
  //！分配空间:
  [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
  
  
}

- (void)setupFrameBuffer {
  
  ///！ 同 颜色缓冲区 操作
  
  GLuint buffer;
  //! 申请的时候  用 glGenRenderbuffers 和 glGenFramebuffers 没区别
  glGenRenderbuffers(1, &buffer);
  
  self.myColorFrameBuffer = buffer;
  
  //! 绑定的时候，必须指定 缓冲区
  
  //生成空间之后，则需要将renderbuffer跟framebuffer进行绑定，
  //调用glFramebufferRenderbuffer函数进行绑定，后面的绘制才能起作用
  
  //5.将_myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 附着点 上。
  
  //! GL_COLOR_ATTACHMENT0 颜色附着点
  glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
  
  
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
  
  //6.接下来，可以调用OpenGL ES进行绘制处理，最后则需要在EGALContext的OC方法进行最终的渲染绘制。这里渲染的color buffer,这个方法会将buffer渲染到CALayer上。- (BOOL)presentRenderbuffer:(NSUInteger)target;

}

///! 开始绘制， 这一步 就 不一样了。
- (void)renderLayer {
  
  //1.开始要写顶点着色器\片元着色器
   //Vertex Shader
   //Fragment Shaer
   
   //已经写好了顶点shaderv.vsh\片元着色器shaderf.fsh
   glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
   glClear(GL_COLOR_BUFFER_BIT);
   
   
   //2.设置视口大小
   CGFloat scale = [[UIScreen mainScreen]scale];
   
   glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
   
   //3.读取顶点\片元着色器程序
   //获取存储路径
   NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
   NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
   
   NSLog(@"vertFile : %@",vertFile);
   NSLog(@"fragFile : %@",fragFile);
   
   //4.加载shader
   self.myPrograme = [self LoadShader:vertFile withFrag:fragFile];
   
   //5.链接
   glLinkProgram(self.myPrograme);
   
   //获取link的状态
   GLint linkStatus;
   glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
   
   //判断link是否失败
   if (linkStatus == GL_FALSE) {
       
       //获取失败信息
       GLchar message[512];
       glGetProgramInfoLog(self.myPrograme, sizeof(message), 0, &message[0]);
       
       //将C语言字符串->OC
       NSString *messageStr = [NSString stringWithUTF8String:message];
       
       NSLog(@"Program Link Error:%@",messageStr);
       return;
       
   }
   
   //5.使用program
   glUseProgram(self.myPrograme);
   
   //6.设置顶点
   //前3个是顶点坐标，后2个是纹理坐标
   GLfloat attrArr[] =
   {
       0.5f, -0.5f, 1.0f,     1.0f, 0.0f,
       -0.5f, 0.5f, 1.0f,     0.0f, 1.0f,
       -0.5f, -0.5f, 1.0f,    0.0f, 0.0f,
       
       0.5f, 0.5f, 1.0f,      1.0f, 1.0f,
       -0.5f, 0.5f, 1.0f,     0.0f, 1.0f,
       0.5f, -0.5f, 1.0f,     1.0f, 0.0f,
   };
   
   //--处理顶点数据---
   GLuint attrBuffer;
   //申请一个缓存标记
   glGenBuffers(1, &attrBuffer);
   //绑定缓存区
   glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
   
   //将顶点缓冲区的CPU内存复制到GPU内存中
   glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
   
   GLuint position = glGetAttribLocation(self.myPrograme, "position");
   
   //2.
   glEnableVertexAttribArray(position);
   
   //3.设置读取方式
   glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
   
   
   //处理纹理数据
   //下一次节从这个位置讲起!!!!!!
   //1.获取纹理的位置-Program
   GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoordinate");
   
   //2.
   glEnableVertexAttribArray(textCoor);
   
   //3.设置读取方式
   glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
   
   //加载纹理!!!
   //通过一个自定义方法来解决加载纹理的方法
   [self setupTexture:@"timg-3"];
   
   
   //1.直接用3D数学的公式来实现旋转
   //2.Uniform
   
   //旋转!!!矩阵->Uniform 传递到vsh,fsh
   
   //需求:旋转10度->弧度?????
   float  radians = 180 * 3.141592f /180.0f;
   
   //是否记得旋转的矩阵公式?
   float s = sin(radians);
   float c = cos(radians);
   
   //构建旋转矩阵--z轴旋转
   GLfloat zRotation[16] = {
           c,-s,0,0,
           s,c,0,0,
           0,0,1.0,0,
           0,0,0,1.0,
   };
   
   //获取位置
   GLuint rotate = glGetUniformLocation(self.myPrograme, "rotateMatrix");
   
   //将这旋转矩阵通过uniform传递进去
   glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
   
   //绘制 -> 数组绘制方式，和索引绘图不一样
   glDrawArrays(GL_TRIANGLES, 0, 6);

   
   [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
   
   //根据这个案例写一个思维导图!
   //1.回顾复习
   //2.写成文章
   //3.面试
   
  
  
}



#pragma mark - priveFunc Shader

///! 加载shader
- (GLuint)LoadShader:(NSString *)vert withFrag:(NSString *)frag {
  
  //! 定时两个 临时着色器对象,用于存储着色器
  GLuint verShader,fragShader;
  
  
  GLuint program = glCreateProgram();
  
  ///! 编译 顶点着色器
  [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
  ///! 编译 渲染片元着色器
  [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
  
  ///! 创建最终的程序
  glAttachShader(program, verShader);
  glAttachShader(program, fragShader);

  ///! 方法已经使用完的 两个着色器
  glDeleteShader(verShader);
  glDeleteShader(fragShader);

  return program;
}

///! 编译shader，OC不会主动帮你编译的
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
  ///! 读取
  NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
  
  
  ///! 将OC 转为 C语言字符串
  const GLchar *source = (GLchar *)[content UTF8String];
  
  ///! 创建shader
  *shader = glCreateShader(type);
  
  ///! 将着色器 附着到 shader 上面
  
  glShaderSource(*shader, 1, &source, NULL);
  
  ///! 将着色器代码 编译出 目标代码
  
  glCompileShader(*shader);
  
  
}


//! 加载纹理
- (GLuint)setupTexture:(NSString *)fileName {
  
  //! 获取图片的GCImage
  CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
  
  ///! 判断图片是否获取成功
  if (spriteImage == nil) {
    NSLog(@"Failed Load Image %@",fileName);
     exit(0);
  }
  
  ///! 读取图片的大小 宽\高
  size_t width = CGImageGetWidth(spriteImage);
  size_t height = CGImageGetHeight(spriteImage);
  
  //! 计数图片的字节数 width * height * 4(RGBA)
  GLubyte *spriteData = calloc(width*height*4, sizeof(GLubyte));
  
  /*创建上下文
   1. data 要渲染的图形内存地址
   2. width 宽
   3. height 高
   4. bitsPerComponent 像素组件的位数
   5. bytesPerRow 一行需要占用多少内存
   6. space 颜色空间
   7. butmapInfo 位图信息
   
   
   */
  CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
  
  
  //! 6
  CGRect rect = CGRectMake(0, 0, width, height);
  
  ///! 使用默认方式绘制
  CGContextDrawImage(spriteContext, rect, spriteImage);
  
  
  ///! 释放空间
  CGContextRelease(spriteContext);
  
  ///! 绑定纹理
  glBindTexture(GL_TEXTURE_2D, 0);
  
  ///! 设置纹理的相关参数
  
  ///!设置 放大过滤器 为 线型过滤器

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  
  ///! 设置缩小过滤器 为 线型过滤器
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

  
  //！ 设置 环绕方式 x,y -> s,t
  //! 设置 s
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  ///! 设置 t
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

  
  /*载入 2d 纹理
   1. target 维度
   2. level 加载的层次， 一般为0
   3. internalformat 颜色组件
   4. width 宽
   5. height 高
   6. border 宽度，一般为0
   7. format 用什么方式去存储它的格式，比如RGBA
   8. type 存储数据的类型
   9. pixels 指针，指向纹理数据的
   */
  
  GLfloat fw = width,fh = height;

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
  
  
  //! 绑定纹理
  glBindTexture(GL_TEXTURE_2D, 0);
  
  ///! 释放数据
  free(spriteData);
  
  return 0;
  
  
}

@end
