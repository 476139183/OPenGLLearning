//
//  MyPointParticleEffect.m
//  OpenGLES-009
//
//  Created by 段雨田 on 2020/5/15.
//  Copyright © 2020 段雨田. All rights reserved.
//
//参数包括初始速度、受力、大小、持续时间、渐隐时间.粒子会根据生命周期进行复用


#import "MyPointParticleEffect.h"
#import "MyVertexAttribArrayBuffer.h"

//用于定义粒子属性的类型
typedef struct {
  GLKVector3 emissionPosition; //发射位置
  GLKVector3 emissionVelocity; //发射速度
  GLKVector3 emissionForce; //发射重力
  GLKVector2 size; //发射大小+持续时间
  GLKVector2 emissionTimeAndLife; //发射时间和寿命
} MyParticleAttributes;

//GLSL程序Uniform 参数
enum {
  MyMVPMatrix, //MVP矩阵
  MySamplers2D, //Samplers2D纹理
  MyElapsedSeconds, //耗时
  MyGravity, //重力
  MyNumUniforms //Uniforms个数
};

//属性标识符
typedef enum {
  MyParticleEmissionPosition = 0, //粒子发射位置
  MyParticleEmissionVelocity, //粒子发射速度
  MyParticleEmissionForce, //粒子发射重力
  MyParticleSize, //粒子发射大小
  MyParticleEmissionTimeAndLife, //粒子发射时间和寿命
} MyParticleAttrib;


@interface MyPointParticleEffect () {
  GLfloat elapsedSeconds; //耗时
  GLuint program; //程序
  GLint uniforms[MyNumUniforms]; //Uniforms数组
}

//顶点属性数组缓冲区
@property (strong, nonatomic, readwrite) MyVertexAttribArrayBuffer  *particleAttributeBuffer;

//粒子个数
@property (nonatomic, assign, readonly) NSUInteger numberOfParticles;

//粒子属性数据
@property (nonatomic, strong, readonly) NSMutableData *particleAttributesData;

//是否更新粒子数据
@property (nonatomic, assign, readwrite) BOOL particleDataWasUpdated;

//！加载shaders
- (BOOL)loadShaders;

//！编译shaders
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file;
//！链接Program
- (BOOL)linkProgram:(GLuint)prog;

//！验证Program
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation MyPointParticleEffect

//初始化
-(id)init
{
    self = [super init];
    if (self != nil) {
       
      //! 1. 初始化纹理
      _texture2d0 = [[GLKEffectPropertyTexture alloc] init];
      _texture2d0.enabled = YES;
      _texture2d0.name = 0;
      _texture2d0.target = GLKTextureTarget2D;
      ///！ 忽略设置的颜色，从纹理获取颜色
      _texture2d0.envMode = GLKTextureEnvModeReplace;
       
      ///！ 2. 设置变换矩阵
      _transform = [[GLKEffectPropertyTransform alloc] init];
      
      /// 3. 初始化重力
      _gravity = kDefaultGravity;
      
      //! 4. 耗时
      _elapsedSeconds = 0.0f;
      
      // 5. 创建粒子属性数据
      _particleAttributesData = [[NSMutableData alloc] init];
      
      
    }
    
    return self;
}

//获取粒子的属性值
- (MyParticleAttributes)particleAtIndex:(NSUInteger)anIndex
{
    
  const MyParticleAttributes *particlesPtr = [self.particleAttributesData mutableBytes];
  
  return particlesPtr[anIndex];
}


//设置粒子的属性
- (void)setParticle:(MyParticleAttributes)aParticle
            atIndex:(NSUInteger)anIndex
{
  
  MyParticleAttributes *particlesPtr = [self.particleAttributesData mutableBytes];
  
  particlesPtr[anIndex] = aParticle;
  
  //
  self.particleDataWasUpdated = YES;

}

//添加一个粒子
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;
{

  //! 创建一新的粒子
  MyParticleAttributes newParticle;
  
  //! 设置相关的参数(位置、速度，重力、大小、耗时)
  newParticle.emissionPosition = aPosition;
  newParticle.emissionVelocity = aVelocity;
  newParticle.emissionForce = aForce;
  newParticle.size = GLKVector2Make(aSize, aDuration);
  newParticle.emissionTimeAndLife = GLKVector2Make(_elapsedSeconds, _elapsedSeconds+aSpan);
  
  // 3. 是否可以复用
  BOOL foundSlot = NO;
  
  
  ///! 粒子的个数
  const long count = self.numberOfParticles;
  //! 优先更新 旧粒子
  for (int i = 0; i < count && !foundSlot; i++) {
    //! 获取旧的粒子
    MyParticleAttributes oldParticle = [self particleAtIndex:i];
    
    ///! 如果发射时常<总耗时
    if (oldParticle.emissionTimeAndLife.y < self.elapsedSeconds) {
      ///! 更新旧粒子属性
      [self setParticle:newParticle atIndex:i];
      //! 是否替换
      foundSlot = YES;
      
    }
    
  }
  
  ///! 如果不替换
  if (!foundSlot) {
    
    ///！ 在粒子数据新增粒子
    [self.particleAttributesData appendBytes:&newParticle length:sizeof(newParticle)];
    
    //! 粒子数据更新完毕
    self.particleDataWasUpdated = YES;
    
  }
  
}

//获取粒子个数
- (NSUInteger)numberOfParticles;
{

  static long last;
  
  ///! 总数据大小/单个粒子结构体大小=粒子个数
  long ret = [self.particleAttributesData length] / sizeof(MyParticleAttributes);
  if (last != ret) {
    last = ret;
    NSLog(@"更新粒子数 %ld",ret);
  }
  
  return ret;
}

- (void)prepareToDraw
{
   
  //! 准备绘制，判断数据
  if (program == 0) {
    [self loadShaders];
  }
  
  if (program != 0) {
    //! 使用 program
    glUseProgram(program);
    
    //! MVP矩阵 变换
    ///! 结果矩阵 = 投影矩阵 * 模型视图矩阵
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix, self.transform.modelviewMatrix);
    
    //！ 将结果矩阵传递给 vsh
    glUniformMatrix4fv(uniforms[MyMVPMatrix], 1, 0, modelViewProjectionMatrix.m);
    
    //! 纹理采样
    glUniform1i(uniforms[MySamplers2D], 0);
    
    //! 粒子的物理重力
    glUniform3fv(uniforms[MyGravity], 1, _gravity.v);
    
    ///! 耗时
    glUniform1fv(uniforms[MyElapsedSeconds], 1, &_elapsedSeconds);
    
    //! 粒子是否更新
    if (self.particleDataWasUpdated) {
      //! 未初始化
      if (self.particleAttributeBuffer == nil && [self.particleAttributesData length] > 0) {
        ///! 将顶点数据 属性 送到 GPU,  数据大小 单个数据的大小
        GLsizeiptr size = sizeof(MyParticleAttributes);
        
        //! 数据个数 = 总大小/单个数据大小
        int count = (int)(self.particleAttributesData.length / size);
        
        self.particleAttributeBuffer = [[MyVertexAttribArrayBuffer alloc] initWithAttribStride:size numberOfVertices:count bytes:self.particleAttributesData.bytes usage:GL_DYNAMIC_DRAW];
      } else {
        ///!  缓冲区已经开辟过了，这个时候产生的新粒子 需要扩容来存储
        //! 为新的数据开辟缓存区,先获取数据大小
        GLsizeiptr size = sizeof(MyParticleAttributes);
        //! 个数
        int count = (int)(self.particleAttributesData.length / size);
        //! 重新开辟空间
        [self.particleAttributeBuffer reinitWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes]];
                
      }
      
      //！更新状态恢复
      self.particleDataWasUpdated = NO;
      
    }
    
    //！ 准备绘制的数据
    
    /* 先准备顶点数据
     * 参数1: 类型
     * 参数2: 读取几个
     * 参数3: 偏移量
     * 参数4: 能否读取
     */
    [self.particleAttributeBuffer prepareToDrawWithAttrib:MyParticleEmissionPosition numberOfCoordinates:3 attribOffset:offsetof(MyParticleAttributes, emissionPosition) shouldEnable:YES];
    
    //！ 发射速度数据
    [self.particleAttributeBuffer prepareToDrawWithAttrib:MyParticleEmissionVelocity numberOfCoordinates:3 attribOffset:offsetof(MyParticleAttributes, emissionVelocity) shouldEnable:YES];
    
    
    //！ 发射重力
    [self.particleAttributeBuffer prepareToDrawWithAttrib:MyParticleEmissionForce numberOfCoordinates:3 attribOffset:offsetof(MyParticleAttributes, emissionForce) shouldEnable:YES];
    
    //! 粒子大小
    [self.particleAttributeBuffer prepareToDrawWithAttrib:MyParticleSize numberOfCoordinates:2 attribOffset:offsetof(MyParticleAttributes, size) shouldEnable:YES];
    
    //! 发射的时间和持续时间
    [self.particleAttributeBuffer prepareToDrawWithAttrib:MyParticleEmissionTimeAndLife numberOfCoordinates:2 attribOffset:offsetof(MyParticleAttributes, emissionTimeAndLife) shouldEnable:YES];
   
    //! 激活纹理单元类型 数量取决于显卡能提供多少个
    glActiveTexture(GL_TEXTURE0);
    
    //！ 判断纹理标记是否为空
    if (self.texture2d0.name != 0 && self.texture2d0.enabled) {
      //! 绑定纹理到纹理标记 上
      glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
    } else {
      glBindTexture(GL_TEXTURE_2D, 0);
    }
    
  }
  
  

}

//绘制
- (void)draw;
{

  //! 禁止深度区缓存数据
  glDepthMask(GL_FALSE);
  
  ///
  /* ! 绘制
   *  GL_POINTS： 点
   * 从0 开始读取
   * 个数
   */
  [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
  
  
  //! 恢复之前的操作
  glDepthMask(GL_TRUE);
  
}

#pragma mark -  OpenGL ES shader compilation

- (BOOL)loadShaders {
  
  GLuint vertShader,fragShader;
  
  NSString *vertShaderPathName, *fragShaderPathName;
  
  //! 创建程序
  program = glCreateProgram();
  
  vertShaderPathName = [[NSBundle mainBundle] pathForResource:
  @"MyPointParticleShader" ofType:@"vsh"];
  

  if (![self compileShader:&vertShader
                      type:GL_VERTEX_SHADER
                        file:vertShaderPathName]) {
       
    NSLog(@"Failed to compile vertex shader");
    return NO;
  }
    
   
  // 创建并编译 fragment shader.
  fragShaderPathName = [[NSBundle mainBundle] pathForResource:
                          @"MyPointParticleShader" ofType:@"fsh"];
   
  if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER
                        file:fragShaderPathName]) {
    NSLog(@"Failed to compile fragment shader");
    return NO;
  }
    
  //将vertex shader 附加到程序.
  glAttachShader(program, vertShader);
  
  //将fragment shader 附加到程序.
  glAttachShader(program, fragShader);
  
  //绑定属性位置
  //这需要在链接之前完成.
  /*
   应用程序通过glBindAttribLocation把“顶点属性索引”绑定到“顶点属性名”，glBindAttribLocation在program被link之前执行。
   void glBindAttribLocation(GLuint program, GLuint index,const GLchar *name)
   program:对应的程序
   index:顶点属性索引
   name:属性名称
   */
  //位置
  glBindAttribLocation(program, MyParticleEmissionPosition,
                       "a_emissionPosition");
  //速度
  glBindAttribLocation(program, MyParticleEmissionVelocity,
                       "a_emissionVelocity");
  //重力
  glBindAttribLocation(program, MyParticleEmissionForce,
                       "a_emissionForce");
  //大小
  glBindAttribLocation(program, MyParticleSize,
                       "a_size");
  //持续时间、渐隐时间
  glBindAttribLocation(program, MyParticleEmissionTimeAndLife,
                       "a_emissionAndDeathTimes");
    
  // Link program 失败
  if (![self linkProgram:program]) {
    NSLog(@"Failed to link program: %d", program);
      
    //link识别,删除vertex shader\fragment shader\program
    if (vertShader) {
      glDeleteShader(vertShader);
      vertShader = 0;
    }
     
    if (fragShader) {
      glDeleteShader(fragShader);
      fragShader = 0;
    }
     
    if (program) {
      glDeleteProgram(program);
      program = 0;
    }
     
    return NO;
  }
    
  // 获取uniform变量的位置.
  //MVP变换矩阵
  uniforms[MyMVPMatrix] = glGetUniformLocation(program,"u_mvpMatrix");
  //纹理
  uniforms[MySamplers2D] = glGetUniformLocation(program,"u_samplers2D");
  //重力
  uniforms[MyGravity] = glGetUniformLocation(program,"u_gravity");
  //持续时间、渐隐时间
  uniforms[MyElapsedSeconds] = glGetUniformLocation(program,"u_elapsedSeconds");
  
  //使用完
  // 删除 vertex and fragment shaders.
  if (vertShader) {
    glDetachShader(program, vertShader);
    glDeleteShader(vertShader);
  }
 
  if (fragShader) {
    glDetachShader(program, fragShader);
    glDeleteShader(fragShader);
  }
  return YES;
  
}


//编译shader
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file {
   
   
  //状态
  GLint status;
  //路径-C语言
  const GLchar *source;
     
    
  //从OC字符串中获取C语言字符串
  //获取路径
     
  source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                encoding:NSUTF8StringEncoding error:nil] UTF8String];
     
  //判断路径
  if (!source) {
    NSLog(@"Failed to load vertex shader");
    return NO;
  }
     
    
  //创建shader-顶点\片元
  *shader = glCreateShader(type);
     
    
  //绑定shader
  glShaderSource(*shader, 1, &source, NULL);
    
    
  //编译Shader
  glCompileShader(*shader);
     
    
  //获取加载Shader的日志信息
  //日志信息长度
  GLint logLength;
  /*
    在OpenGL中有方法能够获取到 shader错误
    参数1:对象,从哪个Shader
    参数2:获取信息类别,
    GL_COMPILE_STATUS       //编译状态
    GL_INFO_LOG_LENGTH      //日志长度
    GL_SHADER_SOURCE_LENGTH //着色器源文件长度
    GL_SHADER_COMPILER  //着色器编译器
    参数3:获取长度
   */
    
  glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
     
    
  //判断日志长度 > 0
  if (logLength > 0) {
    //创建日志字符串
    GLchar *log = (GLchar *)malloc(logLength);
        
    /*
     获取日志信息
     参数1:着色器
     参数2:日志信息长度
     参数3:日志信息长度地址
     参数4:日志存储的位置
     */
        
    glGetShaderInfoLog(*shader, logLength, &logLength, log);
        
    //打印日志信息
    NSLog(@"Shader compile log:\n%s", log);
       
    //释放日志字符串
    free(log);
    return NO;
  }
   
  return YES;
}

//链接program
- (BOOL)linkProgram:(GLuint)prog {
      
  //状态
  GLint status;
  //链接Programe
  glLinkProgram(prog);
  //打印链接program的日志信息
  
  GLint logLength;
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
   
  if (logLength > 0) {

    GLchar *log = (GLchar *)malloc(logLength);
    glGetProgramInfoLog(prog, logLength, &logLength, log);
    NSLog(@"Program link log:\n%s", log);
    free(log);
        
    return NO;
  }
    
  return YES;
}

//验证Program
- (BOOL)validateProgram:(GLuint)prog {
    
    
  //日志长度,验证状态
  GLint logLength, status;
       
       
  //验证prgogram
 
  //http://www.dreamingwish.com/frontui/article/default/glvalidateprogram.html
  /*
 
   glValidateProgram 检测program中包含的执行段在给定的当前OpenGL状态下是否可执行。验证过程产生的信息会被存储在program日志中。验证信息可能由一个空字符串组成，或者可能是一个包含当前程序对象如何与余下的OpenGL当前状态交互的信息的字符串。这为OpenGL实现提供了一个方法来调查更多关于程序效率低下、低优化、执行失败等的信息。
  验证操作的结果状态值会被存储为程序对象状态的一部分。如果验证成功，这个值会被置为GL_TURE，反之置为GL_FALSE。调用函数 glGetProgramiv 传入参数 program和GL_VALIDATE_STATUS可以查询这个值。在给定当前状态下，如果验证成功，那么 program保证可以执行，反之保证不会执行
  
   GL_INVALID_VALUE 错误：如果 program 不是由 OpenGL生成的值.
   GL_INVALID_OPERATION 错误：如果 program 不是一个程序对象.
   */
      
  glValidateProgram(prog);
       
       
  //获取验证的日志信息
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
       
  if (logLength > 0) {
    
    GLchar *log = (GLchar *)malloc(logLength);
    glGetProgramInfoLog(prog, logLength, &logLength, log);
    NSLog(@"Program validate log:\n%s", log);
    free(log);
  }
       
  //获取验证的状态--验证结果
  glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
      
  //根据验证结果返回NO or YES
  if (status == 0) {
    return NO;
  }
     
  return YES;
}

//默认重力加速度向量与地球的匹配
//{ 0，（-9.80665米/秒/秒），0 }假设+ Y坐标系的建立
//默认重力,
const GLKVector3 kDefaultGravity = {0.0f, -9.80665f, 0.0f};

@end
