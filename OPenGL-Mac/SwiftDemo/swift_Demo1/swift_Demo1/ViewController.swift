//
//  ViewController.swift
//  swift_Demo1
//  https://www.jianshu.com/p/0bc2454efb79
//  Created by 段雨田 on 2020/5/20.
//  Copyright © 2020 段雨田. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
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
    let openGLView = MyOpenGLView.init(frame: self.view.bounds, pixelFormat:format)
    self.view.window?.title = "1"
    self.view.addSubview(openGLView!)
  }

  override var representedObject: Any? {
    didSet {

    }
  }

}


