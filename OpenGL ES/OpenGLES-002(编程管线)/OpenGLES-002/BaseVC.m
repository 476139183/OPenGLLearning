//
//  BaseVC.m
//  OpenGLES-002
//
//  Created by 段雨田 on 2020/5/7.
//  Copyright © 2020 段雨田. All rights reserved.

#import "BaseVC.h"
#import "BaseView.h"

@interface BaseVC ()

@property (nonatomic, strong) BaseView *myView;

@end

@implementation BaseVC

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // 删除SceneDelegate：https://blog.csdn.net/weixin_43864837/article/details/104232482

  self.myView = (BaseView *)self.view;
  
  
}





@end
