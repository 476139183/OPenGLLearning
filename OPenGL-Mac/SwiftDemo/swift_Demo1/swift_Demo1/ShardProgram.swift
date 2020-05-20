//
//  ShardProgram.swift
//  swift_Demo1
//
//  Created by 段雨田 on 2020/5/20.
//  Copyright © 2020 段雨田. All rights reserved.
//

import Foundation
import OpenGL
import GLKit

class ShaderProgram {
  
  fileprivate var program:GLuint
  
  init() {
    program = glCreateProgram()
  }
  
}

extension ShaderProgram {
  
  //! 获取日志
  fileprivate func getGLShaderInfoLogo(_ shader : GLuint) -> String {
    
    //! 获取日志长度
    var length:GLint = 0
    glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &length)
    
    var str = [GLchar](repeating:GLchar(0),count:Int(length)+1)
    
    var size:GLsizei = 0
    
    glGetShaderInfoLog(shader, GLsizei(length), &size, &str)
    
    return String(cString: str)
  
  }
  
  
  //! 编译
  fileprivate func comileShader(_ file:String, withType type:GLenum) -> GLuint? {
    
    let path = Bundle.main.resourcePath! + "/" + file
    
    let source = try? String(contentsOfFile: path, encoding: String.Encoding.ascii)
    
    if source == nil {
      print("路径有问题")
      return nil
    }
    
    let cSource = source?.cString(using: .ascii)
    
    var glcSource = UnsafePointer<GLchar>?(cSource!)
    
    //! 链接
    let shader = glCreateShader(type)
    
    var length = GLint((source!).count)
    
    glShaderSource(shader, 1, &glcSource, &length)
    glCompileShader(shader)
    
    //! 获取链接状态
    var result :GLint = 0
    
    glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &result)
    
    if result == GL_FALSE {
      //! 编译失败，可能因为着色器有中文注释
      glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &length)
      
      print("shader 编译失败:%@",getGLShaderInfoLogo(shader))
      return nil
    }
 
    return shader
    
  }
  
  
  //! 获取属性
  func getAttributeLoctaion(_ name : String) -> GLuint? {
    let temp = glGetAttribLocation(program, name.cString(using: .utf8))
    return temp < 0 ? nil : GLuint(temp)
  }
  
  //! 获取 Uniform
  func getUniformLoction(_ name:String) -> GLuint? {
    let temp = glGetUniformLocation(program, name.cString(using: .utf8))
    return temp < 0 ? nil : GLuint(temp)
  }
  
  //! 附着着色器
  func attachShader(_ file:String, withType type :GLint) {
    
    if let shader = comileShader(file, withType: GLenum(type)) {
      glAttachShader(program, shader)
      // We can safely delete the shader now - it won't
      // actually be destroyed until the program that it's
      // attached to has been destroyed.
      glDeleteShader(shader)
    }
    
  }
  
  //! 链接
  func link() {
    
    glLinkProgram(program)
    
    //! 检查链接状态
    var result:GLint = 0
    
    glGetProgramiv(program, GLenum(GL_LINK_STATUS), &result)
    
    if result == GL_FALSE {
      print("链接程序失败!")
    }
    
  }
  
  func use() {
    glUseProgram(program)
  }
  
  
  
}
