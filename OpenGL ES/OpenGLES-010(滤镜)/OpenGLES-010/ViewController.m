//
//  ViewController.m
//  OpenGLES-010
//
//  Created by 段雨田 on 2020/5/18.
//  Copyright © 2020 段雨田. All rights reserved.
//

/*
 
 1. 定义两个GLProgram 分别处理 饱和度 和 色温shader。每一个shader对应转化矩阵/纹理
 
 初始化OpenGLES 配置
 1. 初始化数据
 2. 设置 CAEAGLayer
 3. OpenGL ES 上下文
 4. 初始化帧缓存区
 5. 编译shader
 6. 配置顶点数组信息
 
 滤镜部分：
 1. 饱和度渲染
 2. 色温渲染
 
 
 */

#import "ViewController.h"
#import "GLContainerView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet GLContainerView *glContainerView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  

}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.glContainerView.image = [UIImage imageNamed:@"Lena"];
}

#pragma mark - Action

//! 饱和度
- (IBAction)saturationValueChange:(UISlider *)sender {
  self.glContainerView.saturationValue = sender.value;
}

//! 色温
- (IBAction)tempValueChange:(UISlider *)sender {
  self.glContainerView.colorTempValue = sender.value;
}



@end
