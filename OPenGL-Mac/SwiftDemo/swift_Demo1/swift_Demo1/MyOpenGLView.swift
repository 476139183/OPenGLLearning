//
//  MyOpenGLView.swift
//  swift_Demo1
//
//  Created by 段雨田 on 2020/5/20.
//  Copyright © 2020 段雨田. All rights reserved.
//

import Cocoa

class MyOpenGLView: NSOpenGLView {
  
  
  override init(frame frameRect: NSRect) {
    
    
    super.init(frame: frameRect)
      
    let attr = [
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
      NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
      NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
      NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
      NSOpenGLPixelFormatAttribute(NSOpenGLPFADepthSize), 32,
      0
    ]
          
         
    let format = NSOpenGLPixelFormat(attributes: attr)
    let context = NSOpenGLContext(format: format!, share: nil)
          
    self.openGLContext = context
    
  }
  
  override init?(frame frameRect: NSRect, pixelFormat format: NSOpenGLPixelFormat?) {
    super.init(frame: frameRect, pixelFormat: format)
  }
  
  override func awakeFromNib()
     {
         let attr = [
             NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
             NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
             NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
             NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
             NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
             NSOpenGLPixelFormatAttribute(NSOpenGLPFADepthSize), 32,
             0
         ]
         
         let format = NSOpenGLPixelFormat(attributes: attr)
         let context = NSOpenGLContext(format: format!, share: nil)
         
         self.openGLContext = context
     }
  
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

    
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    self.openGLContext?.makeCurrentContext()
          
    self.render()
           
    self.openGLContext?.flushBuffer()
    
  }
  
  func render() {

    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
     
    var VAO:GLuint = 0

    glGenVertexArrays(1, &VAO)
          
    var VBO:GLuint =  0
    
    glGenBuffers(1, &VBO)
    
    let vertices:[GLfloat] = [
      -0.5, -0.5, 0.0,
      0.5, -0.5, 0.0,
      0.0,  0.5, 0.0
    ]
      
    glBindVertexArray(VAO)
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO)
    glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * vertices.count ,vertices, GLenum(GL_STATIC_DRAW))
    glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    glEnableVertexAttribArray(0)
    glBindVertexArray(0)
     
    let glProgram = ShaderProgram()
    glProgram.attachShader("shader.vsh", withType: GL_VERTEX_SHADER)
    glProgram.attachShader("shader.fsh", withType: GL_FRAGMENT_SHADER)
    glProgram.link()
    glProgram.use()
       
    glBindVertexArray(VAO)
    glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
    glBindVertexArray(0)
   }
  
  
    
}

