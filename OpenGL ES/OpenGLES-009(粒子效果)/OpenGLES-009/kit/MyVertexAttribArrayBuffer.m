//
//  MyVertexAttribArrayBuffer.m
//  OpenGLES-009
//
//  Created by 段雨田 on 2020/5/15.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "MyVertexAttribArrayBuffer.h"

@implementation MyVertexAttribArrayBuffer


//此方法在当前的OpenGL ES上下文中创建一个顶点属性数组缓冲区
- (id)initWithAttribStride:(GLsizeiptr)aStride
          numberOfVertices:(GLsizei)count
                     bytes:(const GLvoid *)dataPtr
                     usage:(GLenum)usage {
    
  self = [super init];
   
  if(self) {
     
    _stride = aStride;
      
    //! size = 步长*个数
    _bufferSizeBytes = _stride * count;
     
    //! 1. 初始化缓冲区 -> VBO
    glGenBuffers(1, &_name);
    glBindBuffer(GL_ARRAY_BUFFER,_name);
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, usage);
   
  }
  
  return self;
}

//此方法加载由接收存储的数据,重新初始化
- (void)reinitWithAttribStride:(GLsizeiptr)aStride
              numberOfVertices:(GLsizei)count
                         bytes:(const GLvoid *)dataPtr {
    
  _stride = aStride;
  _bufferSizeBytes = aStride * count;
  
  // 2.
  glBindBuffer(GL_ARRAY_BUFFER, _name);
  // 3.
  glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, GL_DYNAMIC_DRAW);
  
    
}

// 准备绘制
//当应用程序希望使用缓冲区呈现任何几何图形时，必须准备一个顶点属性数组缓冲区。当你的应用程序准备一个缓冲区时，一些OpenGL ES状态被改变，允许绑定缓冲区和配置指针。
- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable {
 
  
  if (count < 0 || count > 4) {
    NSLog(@"顶点数据有问题 ");
    return;
  }
  
  ////!
  glBindBuffer(GL_ARRAY_BUFFER, _name);
  
  if (shouldEnable) {
    glEnableVertexAttribArray(index);
  }
  
  glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, (GLsizei)_stride, NULL+offset);
  
}

// 数组绘制
//提交由模式标识的绘图命令，并指示OpenGL ES从准备好的缓冲区中的顶点开始，从先前准备好的缓冲区中使用计数顶点。
+ (void)drawPreparedArraysWithMode:(GLenum)mode
                  startVertexIndex:(GLint)first
                  numberOfVertices:(GLsizei)count {
   
  glDrawArrays(mode, first, count);
}

//将绘图命令模式和instructsopengl ES确定使用缓冲区从顶点索引的第一个数的顶点。顶点索引从0开始。
- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count {
  
  glDrawArrays(mode, first, count);
}


- (void)dealloc {
    
  //从当前上下文删除缓冲区
  if (0 != _name) {
    glDeleteBuffers (1, &_name);
    _name = 0;
  }
}


@end
