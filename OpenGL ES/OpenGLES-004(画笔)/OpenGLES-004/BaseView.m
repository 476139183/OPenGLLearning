//
//  BaseView.m
//  OpenGLES-004
//
//  Created by 段雨田 on 2020/5/9.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "BaseView.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <GLKit/GLKit.h>

#import "debug.h"
#import "shaderUtil.h"
#import "fileUtil.h"

// 画笔透明度
#define kBrushOpacity    (1.0 / 2.0)

// 画笔每一笔，有几个点！
#define kBrushPixelStep    2

// 画笔的比例
#define kBrushScale      2

enum {
  PROGRAM_POINT, //0,
  NUM_PROGRAMS   //1,有几个程序
};


///! Uniform 传递的属性类型
enum {
  UNIFORM_MVP,         //0
  UNIFORM_POINT_SIZE,  //1
  UNIFORM_VERTEX_COLOR,//2
  UNIFORM_TEXTURE,     //3
  NUM_UNIFORMS         //4
};


enum {
  ATTRIB_VERTEX, //0
  NUM_ATTRIBS//1
};


//! 定义一个结构体
typedef struct {
  //! vert,frag 分别指向顶点、片元着色器程序文件
  char *vert, *frag;
  //! 创建uniform数组，4个元素，数量由你的着色器程序文件中uniform对象个数
  GLint uniform[NUM_UNIFORMS];
    
  GLuint id;
} programInfo_t;


/*
 * programInfo_t 结构体类型
 * 匿名枚举， NUM_PROGRAMS ，表示第0个元素 赋值
 *
 * "point.vsh" "point.fsh" 分别对应 *vert, *frag
 * 其它值为空
 *
 */
programInfo_t program[NUM_PROGRAMS] = {
  { "point.vsh",   "point.fsh" },
};


//! 纹理结构体
typedef struct {
  GLuint id;
  GLsizei width, height;
} textureInfo_t;


#pragma mark - POINT

@implementation YTPoint

- (instancetype)initWithCGPoint:(CGPoint)point {
  self = [super init];
  if (self) {
    //类型转换
    self.mX = [NSNumber numberWithDouble:point.x];
    self.mY = [NSNumber numberWithDouble:point.y];
  }
    
  return self;
}

@end


#pragma mark - BaseView

@interface BaseView () {
 
  //! Render缓冲区的像素尺寸
  GLint backingWidth;
  GLint backingHeight;
    
  EAGLContext *context;
    
  //! 缓存区frameBuffer\renderBuffer
  GLuint viewRenderBuffer,viewFrameBuffer;
    
  //! 画笔纹理,画笔颜色
  textureInfo_t brushTexture;
  GLfloat brushColor[4];
    
  //! 是否第一次点击
  Boolean firstTouch;
   
  //! 是否需要清屏
  Boolean needsErase;
    
  //! shader object 顶点Shader、片元Shader、Program
  GLuint vertexShader;
  GLuint fragmentShader;
  GLuint shaderProgram;
    
  //! VBO 顶点Buffer
  GLuint vboId;
    
  //! OpenGL 是否初始化
  BOOL initialized;
   
  //! 所有的点
  NSMutableArray *CCArr;
}

@end

@implementation BaseView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  
  self = [super initWithCoder:aDecoder];
  if (self) {
    //! 初始化 图层
    CAEAGLLayer *eagLayer = (CAEAGLLayer *)self.layer;
    
    //！ 设置透明度
    eagLayer.opaque = YES;
    
    //TODO: [NSNumber numberWithBool:NO] 会让真机闪烁的bug
    //! 设置 参数
    eagLayer.drawableProperties = @{
      kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:YES],
      kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
    };
    
    //! 初始化上下文
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context || ![EAGLContext setCurrentContext:context]) {
      //!
      NSLog(@"上下文失败");
      return nil;
    }
    
    //！ 设置比例因子
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    
    //! 是否需要清屏
    needsErase = YES;
    
  }
   
  return self;
}

//CCView layOut
- (void)layoutSubviews {
  
  [EAGLContext setCurrentContext:context];
  
  if (!initialized) {
    initialized = [self initGL];
    
  } else {
    ///! 重新调整 layer
    [self resizeFromLayer:(CAEAGLLayer *)self.layer];
  }
  
  //! 如果需求清屏
  if (needsErase) {
    [self erase];
    needsErase = NO;
  }
    
  
}

- (BOOL)initGL {
  
  ///！ 1. 设置标记
  glGenFramebuffers(1, &viewFrameBuffer);
  glGenRenderbuffers(1, &viewRenderBuffer);
  
  //! 2. 绑定标记
  glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
  glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
  
  //! 3. 分配空间: 绑定一个 EAGLDrawable 对象，存储到缓冲区中
  /*
   * GL_RENDERBUFFER 表示当前绑定的缓冲区 为 渲染缓冲区
   *  渲染到 self.layer 上
   */
  [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];
  
  ///！ 4. 将 frameBuffer 和 RenderBuffer 联系一起
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);
  
  ///! 5. 获取渲染缓冲区的像素 区域
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
  
  //! 6. 检查 GL_FRAMBUFFER 状态
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    NSLog(@"Make Complete FramBuffer object failed! %x",glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return NO;
  }
  
  ///! 7.设置 视口
  glViewport(0, 0, backingWidth, backingHeight);
  
  //! 8. 创建顶点缓冲区对象 保持数据
  glGenBuffers(1, &vboId);
  
  //! 9. 加载画笔纹理
  brushTexture = [self textureFromName:@"Particle.png"];
  
  //! 11 加载shader
  [self setupShaders];
  
  //!  12. 开启颜色混合，实现模糊效果
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
  
  //! 13. 回放 路径 ”加油“ 的 顶点数据
  NSString *path = [[NSBundle mainBundle] pathForResource:@"brushOli" ofType:@"string"];
  
  NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
  
  ///! 顶点数组，开辟空间
  CCArr = [NSMutableArray array];
  
  ///! 解析到数组
  NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
  
  ///! 遍历数组，转为 YTPoint 模型
  for (NSDictionary *dict in jsonArray) {
    YTPoint *point = [YTPoint new];
    point.mX = [dict objectForKey:@"mX"];
    point.mY = [dict objectForKey:@"mY"];
    
    [CCArr addObject:point];
  }
  
  //! 绘制
  [self performSelector:@selector(paint) withObject:nil  afterDelay:0.5];
  
  return YES;
  
}

///!
- (void)paint {
  
  ///! 每次取两个点，才能绘制成线条
  for (int i = 0; i < CCArr.count - 1; i+=2) {
    
    YTPoint *yP1 = CCArr[i];
    YTPoint *yP2 = CCArr[i+1];
    
    CGPoint point1,point2;
    point1.x = yP1.mX.floatValue;
    point1.y = yP1.mY.floatValue;

    point2.x = yP2.mX.floatValue;
    point2.y = yP2.mY.floatValue;
    
    ///! 绘制线条
    [self renderLineFromPoint:point1 toPoint:point2];
  }

    
}

//! 在用户触摸的地方绘制屏幕上的线条
- (void)renderLineFromPoint:(CGPoint)start toPoint:(CGPoint)end {
    
  //! 将两个点 绘制成 线段
  ///! 顶点缓冲区
  static GLfloat *vertexBuffer = NULL;
  
  //! 顶点 MAX
  static NSUInteger vertexMax = 64;
  
  ///! 顶点个数
  NSUInteger vertexCount = 0, count;
  
  
  ///! 缩放因子
  CGFloat scale = self.contentScaleFactor;
  
  ///!
  start.x *= scale;
  start.y *= scale;
  
  end.x *= scale;
  end.y *= scale;
  
  ///! 开辟数组缓冲区
  if (vertexBuffer == NULL) {
    vertexBuffer = malloc(vertexMax * 2 * sizeof(GLfloat));
  }
    
  /* 通过将 起点start 到 终点end 的轨迹，分解成若干点，从而使线条圆润
   *
   * ceilf() 向上取整，
   */
  
  //！ 求两点的直线距离 勾股定理。
  float poorX = (end.x - start.x);
  float poorY = (end.y - start.y);
  float seq = sqrtf(poorX*poorX + poorY*poorY);
  
  //! 向上取整,求得start点和end点的 直线距离/点的间隔   需要额外产生多少个点
  NSInteger pointCount = ceilf(seq/kBrushPixelStep);
  
  //！ 点的个数必须大于1
  count = MAX(pointCount, 1);
  
  for (int i = 0; i < count; i++) {
   
    if (vertexCount == vertexMax) { //! 如果顶点 == 缓冲区顶点容量，需要扩容
      vertexMax = 2 * vertexMax;
      ///! 数组动态扩容, *2 是因为要同时存x和y
      vertexBuffer = realloc(vertexBuffer, vertexMax * 2 * sizeof(GLfloat));
    }
    
    ///! 修改 vertexBuffer数组的值
    ///! 将 start 到 end 距离之间的点，存储到vertexBuffer
    ///！
    /*
     * x = start.x + (end.x - start.x) * (i/count);
     * y = start.y + (end.y - start.y) * (i/count);
     * vertexBuffer 这里 相当于2维数组，同时存 x 和 y 坐标
     */
    vertexBuffer[2 * vertexCount + 0] = start.x + (end.x - start.x) * ((GLfloat)i/count);
    vertexBuffer[2 * vertexCount + 1] = start.y + (end.y - start.y) * ((GLfloat)i/count);
    
    vertexCount += 1;
  }
  
  ///！ 加载数据到 vertex buffer
  glBindBuffer(GL_ARRAY_BUFFER, vboId);
  
  /* 将数据 从 CPU 拷贝到GPU
   * 总大小
   * 数据源
   * GL_DYNAMIC_DRAW 动态绘制，如果不变，可以使用 GL_STATIC_DRAW
   */
  glBufferData(GL_ARRAY_BUFFER, vertexCount * 2 * sizeof(GLfloat), vertexBuffer, GL_DYNAMIC_DRAW);
  
  ///！ 传递给 顶点着色器
  
  glEnableVertexAttribArray(ATTRIB_VERTEX);
  glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
  
  ///! 开始绘制
  glUseProgram(program[PROGRAM_POINT].id);
  
  ///! 通过数组绘制
  glDrawArrays(GL_POINTS, 0, (int)vertexCount);
  
  ///! 显示
  glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
  
  [context presentRenderbuffer:GL_RENDERBUFFER];
  
  
}

- (void)setupShaders {
  
  for (int i = 0; i < NUM_PROGRAMS; i++) {
    ///! 读取顶点程序
    char *vsrc = readFile(pathForResource(program[i].vert));
    ///！读取片元程序
    char *fsrc = readFile(pathForResource(program[i].frag));
    
    /*
    //! char-NSString , 减1 是因为会把结尾的 '\0' 算进去，这个得验证一下
    NSString *vsrcStr = [[NSString alloc] initWithBytes:vsrc length:strlen(vsrc)-1 encoding:NSUTF8StringEncoding];
    
    NSString *fsrcStr = [[NSString alloc] initWithBytes:fsrc length:strlen(fsrc)-1 encoding:NSUTF8StringEncoding];
    //打印着色程序中的代码
    NSLog(@"vsrc:%@",vsrcStr);
    NSLog(@"fsrc:%@",fsrcStr);
    */

    //! 属性
    GLsizei attribCt = 0;
    
    //! 创建属性字符串数组
    GLchar *attribUser[NUM_ATTRIBS];
    ///! 属性的标记数组
    GLint attrib[NUM_ATTRIBS];
    
    //! 属性名称
    GLchar *attrbName[NUM_ATTRIBS] = {
      "inVertex"
    };
    
    //! Uniform
    const GLchar *uniformName[NUM_UNIFORMS] = {
      "MVP",
      "pointSize",
      "vertexColor",
      "texture"
    };
    
    //! 遍历
    for (int j = 0; j < NUM_ATTRIBS; j++) {
      //! 判断字符串后者是不是前者的子串
      if (strstr(vsrc, attrbName[j])) {
        ///! attribute 的个数
        attrib[attribCt] = j;
        
        attribUser[attribCt++] = attrbName[j];
        
      }
      
    }
    
    //! 根据 shaderUtil.c 简化代码
    /*
     * 参数1: 顶点着色器的内容
     * 参数2: 片元着色器的内容
     * 参数3: attribute 变量的个数
     * 参数4: attribute 变量的名称
     * 参数5: 当前 attribute的位置
     * 参数6: uniform的名称
     * 参数7: program中 Uniform的地址
     * 参数8: program的地址
     */
    glueCreateProgram(vsrc, fsrc, attribCt, (const char **)&attribUser[0], attrib, NUM_UNIFORMS, &uniformName[0], program[i].uniform, &program[i].id);
    
    //! 释放
    free(vsrc);
    free(fsrc);
    
    //！ 使用 program
    if (i == PROGRAM_POINT) {
      glUseProgram(program[PROGRAM_POINT].id);
      
      //! 为当前的程序 传递 uniform 变量值
      //! 传递当前的纹理
      glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0);
      //！ 传递投影矩阵 Ortho 正投影
      GLKMatrix4 projectionMatix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
      //! 模型视图矩阵
      GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
      
      ///! 矩阵相乘 得到结果矩阵，作为模型视图变换矩阵，
      GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatix, modelViewMatrix);
      
      
      /* 传到 顶点着色器中的MVP,用4维矩阵
       *  mvp
       *
       *
       *
       */
      glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
      
      
      ///! 点的大小
      glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], brushTexture.width/kBrushScale);
      
      ///! 笔刷的颜色
      glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
      
      
    }
    
    
  }
  
  glError();
  
}


// 创建一个纹理图片
- (textureInfo_t)textureFromName:(NSString *)name {
  //! 图片
  CGImageRef brushImage;
  //! 上下文
  CGContextRef brushContext;
  
  //! 数据
  GLubyte *brushData;
  
  //! 图片宽高
  size_t width,height;
  
  //! 纹理ID
  GLuint texID;
  
  //纹理信息
  textureInfo_t texture;
  
   
  brushImage = [UIImage imageNamed:name].CGImage;
  
  
  //! 获取图片宽高
  width = CGImageGetWidth(brushImage);
  height = CGImageGetHeight(brushImage);
  
  //! 创建 位图数据
  brushData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
  
  /* 创建一个 位图 绘制环境，也就是 位图上下文
   * 参数1: 指向 渲染 内容的地址
   * 参数2，3：渲染对象的宽高，
   * 参数4: 颜色组件的位数， 8 位
   * 参数5: 位图 每一行 需要的 比特 数  也就是 width * 4
   * 参数6: 颜色空间
   * 参数7 颜色通道： RGBA -> kCGImageAlphaPremultipliedLast
   *
   */
  brushContext = CGBitmapContextCreate(brushData, width, height, 8, width * 4, CGImageGetColorSpace(brushImage), kCGImageAlphaPremultipliedLast);
  
  ///! 绘制
  CGContextDrawImage(brushContext, CGRectMake(0.0, 0.0f, (CGFloat)width, (CGFloat)height), brushImage);

  ///!  先释放 位图上下文
  CGContextRelease(brushContext);
  
  //! 给纹理生成标记
  glGenTextures(1, &texID);
  //! 绑定纹理
  glBindTexture(GL_TEXTURE_2D, texID);
  
  //! 设置 纹理相关参数
  ///! 设置缩小过滤器 为 线型过滤
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  
  

  /* 生成2d纹理
   * 参数1: GL_TEXTURE_2D 生成2d纹理
   * 参数2 ：0
   * 参数3: 颜色组件, GL_RGBA
   * 参数4，5 宽高
   * 参数6: 宽度，0
   * 参数7: 像素的颜色格式，
   * 参数8： 像素数据存储类型
   * 参数9: 纹理数据
   */
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (int)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, brushData);
  free(brushData);
  
  
  //!
  texture.id = texID;
  texture.width = (GLsizei)width;
  texture.height = (GLsizei)height;
  
  
  return texture;
}

//! 调整图层
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer {
 
  //! 根据现有的 重新绑定 和 分配
  glBindBuffer(GL_RENDERBUFFER, viewRenderBuffer);
  
  [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
   
  /// 获取 渲染缓存区的像素宽度 --将渲染缓存区像素宽度存储在backingWidth
  glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH, &backingWidth);
  
  /// 获取 渲染缓存区的像素高度--将渲染缓存区像素高度存储在backingHeight
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
  
  //! 检查GL_FRAMEBUFFER缓存区状态
  
  if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
         
    NSLog(@"Make compelete framebuffer object failed!%x",glCheckFramebufferStatus(GL_FRAMEBUFFER));
    return NO;
  }
  
  //! 更新投影矩阵、模型视图矩阵
     // 投影矩阵
     /*
      投影分为正射投影和透视投影，我们可以通过它来设置投影矩阵来设置视域，在OpenGL中，默认的投影矩阵是一个立方体，即x y z 分别是-1.0~1.0的距离，如果超出该区域，将不会被显示
      
      正射投影(orthographic projection)：GLKMatrix4MakeOrtho(float left, float righ, float bottom, float top, float nearZ, float farZ)，该函数返回一个正射投影的矩阵，它定义了一个由 left、right、bottom、top、near、far 所界定的一个矩形视域。此时，视点与每个位置之间的距离对于投影将毫无影响。
      
      透视投影(perspective projection)：GLKMatrix4MakeFrustum(float left, float right,float bottom, float top, float nearZ, float farZ)，该函数返回一个透视投影的矩阵，它定义了一个由 left、right、bottom、top、near、far 所界定的一个平截头体(椎体切去顶端之后的形状)视域。此时，视点与每个位置之间的距离越远，对象越小。
      
      在平面上绘制，只需要使正投影就可以了！！
     
  */
  
  /* 设置 正投影
   -1,1 是 远近裁剪面，所以要设置一样的
   */
  GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, backingWidth, 0, backingHeight, -1, 1);
  
  //! 设置了投影矩阵之后，就要 设置模型矩阵，这里不需要什么变化，所以可以使用 单元矩阵
  GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
 
  ///! 矩阵相乘
  GLKMatrix4 MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
 
  
  /*   结果矩阵 传递给 shader 上面去，因为不需要更改，所以使用 Uniform
   
       void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);
   
       功能：为当前程序对象指定uniform变量值
       参数1：location 指明要 更改的uniform变量的位置 MVP
       参数2：count 指定将要被修改的矩阵的数量
       参数3：transpose 矩阵的值被载入变量时，是否要对矩阵进行变换，比如转置！
       参数4：value ，指向将要用于更新uniform变量MVP的数组指针
       */
  glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
  
  //! 更新视口
  glViewport(0, 0, backingWidth, backingHeight);
  
  return YES;
}

//清空屏幕
- (void)erase {
  
  //! 先绑定 顶点缓冲区，
  glBindFramebuffer(GL_RENDERBUFFER, viewFrameBuffer);
  //！进行清空
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
  
  ///！ 清理颜色缓冲区
  glClear(GL_COLOR_BUFFER_BIT);
  
  //! 绑定 渲染缓冲区 -> 显示渲染缓冲区
  glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
  [context presentRenderbuffer:GL_RENDERBUFFER];

}


- (void)setBrushColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue {
  
  //!RGBA
  brushColor[0] = red * kBrushOpacity;
  brushColor[1] = green * kBrushOpacity;
  brushColor[2] = blue * kBrushOpacity;
  brushColor[3] = kBrushOpacity;
  
  //! 如果已经初始化 才可以使用 program
  if (initialized) {
    //! 使用 program[0].id 程序
    glUseProgram(program[PROGRAM_POINT].id);
    //! 将颜色值 brushColor 传递到 vertexColor中，修改画笔颜色
    glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor);
      
  }
    
}

- (void)dealloc {
   
  //安全释放viewFrameBuffer、viewRenderBuffer、brushTexture、vboId、context
     
  if (viewFrameBuffer) {
    glDeleteFramebuffers(1, &viewFrameBuffer);
    viewFrameBuffer = 0;
     
  }
       
      
  if (viewRenderBuffer) {
    glDeleteRenderbuffers(1, &viewRenderBuffer);
    viewRenderBuffer = 0;
     
  }
       
       
       
  if (brushTexture.id) {
    glDeleteTextures(1, &brushTexture.id);
    brushTexture.id = 0;
     
  }
     
  if (vboId) {
    glDeleteBuffers(1, &vboId);
    vboId = 0;
  }
       
      
  if ([EAGLContext currentContext] == context) {
    [EAGLContext setCurrentContext:nil];
  }
  
}

#pragma mark -- Touch Click
//点击屏幕开始
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  
  //!
  CGRect bounds = [self bounds];
  
  //! 获取 touch
  UITouch *touch = [[event touchesForView:self] anyObject];
  
  firstTouch = YES;
  
  _location = [touch locationInView:self];
  
  _location.y = bounds.size.height - _location.y;
  
  
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  
  CGRect bounds = [self bounds];
  UITouch *touch = [[event touchesForView:self] anyObject];

  if (firstTouch) {
    firstTouch = NO;
    
    _previousLocation = [touch precisePreviousLocationInView:self];
    _previousLocation.y = bounds.size.height - _previousLocation.y;
    
  } else {
    ///!  一直连续画，没离开屏幕
    _location = [touch locationInView:self];
    _location.y = bounds.size.height - _location.y;

    _previousLocation  = [touch precisePreviousLocationInView:self];
    _previousLocation.y = bounds.size.height - _previousLocation.y;
    
  }
  
  ///！ 开始绘制
  [self renderLineFromPoint:_previousLocation toPoint:_location];
  
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  
  CGRect bounds = [self bounds];
  UITouch *touch = [[event touchesForView:self] anyObject];
  
  if (firstTouch) {
    firstTouch = NO;
    _previousLocation  = [touch precisePreviousLocationInView:self];
    _previousLocation.y = bounds.size.height - _previousLocation.y;
    
    [self renderLineFromPoint:_previousLocation toPoint:_location];
  }

}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  NSLog(@"Touch Cancelled");
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

@end
