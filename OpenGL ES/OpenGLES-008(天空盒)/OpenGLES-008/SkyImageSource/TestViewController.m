//
//  TestViewController.m
//  OpenGLES-008
//
//  Created by 段雨田 on 2020/5/14.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "TestViewController.h"

@interface TestViewController ()

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation TestViewController


//!TODO:这里演示 怎么把 天空盒 的 原型图片 切割成 能使用的天空盒 图片
- (void)viewDidLoad {
  [super viewDidLoad];
  
  ///! 显示图片 100*600
  self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100 * 6)];
  UIImage *image = [UIImage imageNamed:@"skybox1_test"];
  self.imageView.image = image;
  [self.view addSubview:self.imageView];
  
  //! 处理图片
  long length = image.size.width/4;
  
  //! 图片顶点索引
  long indices[] = {
    //! right
    length*2,length,
    //! left
    0,length,
    //! top
    length,0,
    //! bottom
    length,length*2,
    //！front
    length,length,
    //! back
    length*3,length
    
  };
  
  //! 通过顶点索引，指定图片的个数
  long faceCount = sizeof(indices)/sizeof(indices[0])/2;
  
  //! 获取 图片大小， 单个图片大小=length*length,那么整个长图的大小={length,length * faceCount}
  CGSize imageSize = CGSizeMake(length, length * faceCount);
  
  ///! 创建基于位图的图形上下文，并使其 作为当前上下文
  UIGraphicsBeginImageContext(imageSize);
  
  for (int i = 0; i+2 <= faceCount * 2; i+=2) {
    //! 创建图片
    CGImageRef cgImage = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(indices[i], indices[i+1], length, length));
    //! CGImage 转为 UIImage
    UIImage *temp = [UIImage imageWithCGImage:cgImage];
    //! 绘制图片
    [temp drawInRect:CGRectMake(0, length * i / 2, length, length)];
    
  }
  
  ///! 获取处理好的图片
  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
  
  //7.保存图片到沙盒
  //!1.指定图片路径
  NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"skyImage.png"];
  
  //2.打印路径
  NSLog(@"image path:%@",path);
  
  //获取图片的数据
  NSData *cImageData = UIImagePNGRepresentation(finalImage);
  
  //将数据写入到文件
  BOOL writeStatus = [cImageData writeToFile:path atomically:YES];
    
  if (writeStatus) {
    NSLog(@"处理图片成功!");
  } else {
    NSLog(@"处理图片失败!");
  }

}



@end
