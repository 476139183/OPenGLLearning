//
//  MySkyBoxEffect.m
//  OpenGLES-008
//
//  Created by 段雨田 on 2020/5/14.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "MySkyBoxEffect.h"

//! 立方体 2 * 6 顶点索引数 绘制立方体的三角形带索引
const static int  kSkyboxNumVertexIndices = 14;

//! 立方体有 8个角 * 3 = 24
const static int  kSkyboxNumCoords = 24;

enum {
  MyMVPMatrix, //! MVP变换矩阵
  MySamplersCube, //! 立体纹理贴图
  MyNumUniforms  //! Uniform数量
};

@interface MySkyBoxEffect() {
  GLuint vertexBufferID; //! 顶点缓冲区ID
  GLuint indexBufferID;  //! 索引缓冲区ID
  GLuint program;        //! 程序
  GLuint vertexArrayID;  //! 顶点数据ID
  GLint uniforms[MyNumUniforms]; //! Uniform数组
}

//! 加载Shader
- (BOOL)loadShaders;

//! 编译Shader
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file;
//! 链接Program
- (BOOL)linkProgram:(GLuint)prog;

//! 验证Program
- (BOOL)validateProgram:(GLuint)prog;

@end


@implementation MySkyBoxEffect

- (instancetype)init {
   
  self = [super init];
   
  if (self) {
    //! 初始化纹理
    _textureCubeMap = [[GLKEffectPropertyTexture alloc] init];
    //! 是否可以使用原始纹理
    _textureCubeMap.enabled = YES;
    //! 该纹理在OpenGL ES 的名称
    _textureCubeMap.name = 0;
    
    /*! 使用纹理的类型 2D or 立体贴图，这些选择立体贴图
     * GLKTextureTarget2D 等价于 GL_TEXTURE_2D 2D纹理
     * GLKTextureTargetCubeMap 等价于 GL_TEXTURE_CUBE_MAP
     */
    _textureCubeMap.target = GLKTextureTargetCubeMap;
   
    
    /*! 用纹理计算 输出的片段颜色模式（输出颜色 既 显示的颜色）
     GLKTextureEnvModeReplace : 输出的颜色由纹理获取，忽略输入的颜色
     GLKTextureEnvModeModulate : 输出的颜色通过纹理颜色与输入颜色计算所得
     GLKTextureEnvModeDecal : 输出颜色通过纹理的alpha组件来混合纹理颜色和输入颜色来计算
     */
    _textureCubeMap.envMode = GLKTextureEnvModeReplace;
   
    //！  变换管道
    _transform = [[GLKEffectPropertyTransform alloc] init];
    ///! 中心点
    self.center = GLKVector3Make(0, 0, 0);
    //! box 尺寸: 立方体
    self.xSize = self.ySize = self.zSize = 1.0f;
    
    //! 立方体 8个角 的 顶点信息
    const float vertices[kSkyboxNumCoords] = {
      -0.5, -0.5,  0.5,
      0.5, -0.5,  0.5,
      -0.5,  0.5,  0.5,
      0.5,  0.5,  0.5,
      -0.5, -0.5, -0.5,
      0.5, -0.5, -0.5,
      -0.5,  0.5, -0.5,
      0.5,  0.5, -0.5,
    };
    
    // VBO: 顶点缓冲区对象
    /* 创建缓存对象，并返回顶点缓存标示符号
     *
     */
    glGenBuffers(1, &vertexBufferID);
    //! 将缓存区绑定到相应的缓存区上-数组缓存区
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
    //! 将数据拷贝到缓冲区上
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    // 绘制 立方体的 三角形索引数组
    const GLubyte indices[kSkyboxNumVertexIndices] = {
      1, 2, 3, 7, 1, 5, 4, 7, 6, 2, 4, 0, 1, 2
    };
    
    //! 创建缓冲区，返回标记
    glGenBuffers(1, &indexBufferID);
    //! 将标记对应的缓冲区 绑定到相应的缓存区上-索引缓存区
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    //! 将数据拷贝到缓冲区上
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    
    
  }
   
  return self;
}

//! 准备绘制
- (void)prepareToDraw {
  
  //!
  if (program == 0) {
    //! 加载 program
    [self loadShaders];
  }
  
  if (program != 0) {
    //! 1. 使用program
    glUseProgram(program);
    
    //! 2. 移动天空盒模型 视图矩阵
    GLKMatrix4 skyboxModelView = GLKMatrix4Translate(self.transform.modelviewMatrix, self.center.x, self.center.y, self.center.z);
    
    //! 放大天空盒子
    skyboxModelView = GLKMatrix4Scale(skyboxModelView, self.xSize, self.ySize, self.zSize);
     
    //! 投影矩阵
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix, skyboxModelView);
    
  
    /* 然后 将 矩阵 传递到 顶点着色器 使用 Uniform
     * glUniformMatrix4fv(<#GLint location#>, <#GLsizei count#>, <#GLboolean transpose#>, <#const GLfloat *value#>)
     * location 位置标记
     * count 数据个数
     * 是否需要转置
     * 数据源
     */
    
    //! MVP:
    glUniformMatrix4fv(uniforms[MyMVPMatrix], 1, GL_FALSE, modelViewProjectionMatrix.m);
    
    //! 纹理
    glUniform1i(uniforms[MySamplersCube], 0);
    
    //!VAO
    if (vertexArrayID == 0) {
      //! 没有开辟空间
      //QES 扩展类，设置顶点属性,为 vertexArrayID 申请标记
      glGenVertexArraysOES(1, &vertexArrayID);
      glBindVertexArrayOES(vertexArrayID);
      
      //！ 允许读取顶点数据
      glEnableVertexAttribArray(GLKVertexAttribPosition);
      ///！并且 将 vertexBufferID 绑定到 数组缓冲区
      glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID);
      glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, 0);
    } else {
      //! 恢复，重新绑定
      glBindVertexArrayOES(vertexArrayID);
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBufferID);
    
    //! 判断 纹理是否可用
    if (self.textureCubeMap.enabled) {
      //!
      glBindTexture(GL_TEXTURE_CUBE_MAP, self.textureCubeMap.name);
    } else {
      ///! 绑定一个空的
      glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    }
    
  }
  
    
}

//! 绘制
- (void)draw {

  //! 索引绘制
  glDrawElements(GL_TRIANGLE_STRIP, kSkyboxNumVertexIndices, GL_UNSIGNED_BYTE, NULL);
  
}

- (void)dealloc {
  if (vertexArrayID != 0) {
    glDeleteVertexArraysOES(1, &vertexArrayID);
  }
  
  if (indexBufferID != 0) {
    glBindBuffer(GL_ARRAY_BUFFER, 0); //！可写可不写
    glDeleteBuffers(1, &indexBufferID);
  }
  
  if (indexBufferID != 0) {
    glDeleteBuffers(1, &indexBufferID);
  }
  
  if (program != 0) {
    glDeleteProgram(program);
  }

}

#pragma mark -  OpenGL ES shader compilation
//! 加载着色器
- (BOOL)loadShaders {
  
  GLuint vertShader,fragShader;
  NSString *vertShaderPathName, *fragShaderPathName;
  
  //! 创建program
  program = glCreateProgram();
  
  //! 指定顶点着色器的路径
  vertShaderPathName = [[NSBundle mainBundle] pathForResource:@"MySkyboxShader" ofType:@"vsh"];
  
  //! 编译顶点着色器
  if ([self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathName] == NO) {
    NSLog(@"编译顶点着色器失败");
    return NO;
  }
  
  //!
  fragShaderPathName = [[NSBundle mainBundle] pathForResource:@"MySkyboxShader" ofType:@"fsh"];
  
  if ([self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathName] == NO) {
       
    NSLog(@"编译片元着色器失败");
     return NO;
  }

  ///！着色器 附着到 program 上
  glAttachShader(program, vertShader);
  glAttachShader(program, fragShader);

  ///! 绑定属性位置
  glBindAttribLocation(program, GLKVertexAttribPosition, "a_position");
  
  //! 链接
  if ([self linkProgram:program] == NO) {
    NSLog(@"程序 链接 失败");
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
  
  //!
  uniforms[MyMVPMatrix] = glGetUniformLocation(program, "u_mvpMatrix");
  uniforms[MySamplersCube] = glGetUniformLocation(program, "u_samplersCube");
  
  ///! 生成程序，着色器可以删除了
  if (vertShader) {
    //! 移除附着点，并删除
    glDetachShader(program, vertShader);
    glDeleteShader(vertShader);
  }
  
  if (fragShader) {
    //! 移除附着点，并删除
    glDetachShader(program, fragShader);
    glDeleteShader(fragShader);
  }
  
  return YES;
}


//! 编译着色器程序
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file {
  
  //! 状态
  GLint status;
  
  //! 路径->C语言字符串
  const GLchar *source;
  
  source = [[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
  
  if (!source) {
    NSLog(@"路径有问题");
    return NO;
  }
  
  *shader = glCreateShader(type);
  
  //! 绑定shader
  glShaderSource(*shader, 1, &source, NULL);
  //! 编译
  glCompileShader(*shader);
  
  //! 获取 shader 加载的日志信息
  GLint logLength;
  /*
   glGetShaderiv (GLuint shader, GLenum pname, GLint* params)
   参数1:着色器
   参数2: 获取信息的类型，
   GL_COMPILE_SRATUS:编译状态
   GL_INFO_LOG_LENGTH 日志长度
   GL_SHADER_SOURCE_LENGTH 着色器源文件的长度 字符长度
   GL_SHADER_COMPLIER
   
   
   */
  glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    //! 创建日志字符串
    GLchar *log = (GLchar *)malloc(logLength);
    //! 获取 日志信息
    glGetShaderInfoLog(*shader, logLength, &logLength, log);
    
    NSLog(@"shader Compile Log : %s\n",log);
    free(log);
    return NO;
  }
  
  return YES;
}


//! 链接program
- (BOOL)linkProgram:(GLuint)prog {
  
  //! 状态
//  GLint status;
  glLinkProgram(prog);
  
  //! 日志
  GLint logLength;
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
  
  if (logLength > 0) {
    GLchar *log = malloc(logLength);
    glGetProgramInfoLog(prog, logLength, &logLength, log);
    NSLog(@"program link Log : %s\n",log);
    free(log);
    return NO;
  }
  
  return YES;
}


//! 验证Program，看其是否能在当前环境执行
- (BOOL)validateProgram:(GLuint)prog {
  
  GLint logLength,status;
  //！ 验证,会产生验证日志信息
  glValidateProgram(prog);
  
  ///! 获取验证日志信息
  glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    GLchar *log = malloc(logLength);
    
    glGetProgramInfoLog(prog, logLength, &logLength, log);
    
    NSLog(@"program validate Log : %s\n",log);
    free(log);
    
    //！获取验证状态
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
      return NO;
    }
    
  }
  
  return YES;
}

@end
