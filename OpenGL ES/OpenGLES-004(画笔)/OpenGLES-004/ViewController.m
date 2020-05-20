//
//  ViewController.m
//  OpenGLES-004
//
//  Created by 段雨田 on 2020/5/9.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"
#import "SoundEffect.h"
#import "BaseView.h"


// 亮度
#define kBrightness             1.0
// 饱和度
#define kSaturation             0.45
// 调色板高度
#define kPaletteHeight      30
// 调色板大小
#define kPaletteSize      5
// 最小擦除 时间间隔
#define kMinEraseInterval    0.5

//填充率 左 上 右
#define kLeftMargin        10.0
#define kTopMargin        10.0
#define kRightMargin      10.0


@interface ViewController () {
  //! 清除屏幕声音
  SoundEffect      *erasingSound;
  //! 选择颜色声音
  SoundEffect      *selectSound;
  
  CFTimeInterval    lastTime;
  
}

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  [self setUpUI];

}


- (void)setUpUI {
  
  ///! 设置分段选择器
  [self createSegmented];
  
  
  /* 定义起始颜色 HSB颜色
    
   Hue:色调 = 选择的index/颜色选择总数
   saturation:饱和度
   brightness:亮度
   
   */
  CGColorRef color = [UIColor colorWithHue:(CGFloat)2.0/(CGFloat)kPaletteSize saturation:kSaturation brightness:kBrightness alpha:1.0].CGColor;

   
  //根据颜色值，返回颜色相关的颜色组件,
  const CGFloat *components = CGColorGetComponents(color);

  ///! 根据颜色组件  设置默认的 画笔颜色
  [(BaseView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
  
  ///！加载声音 清除声音、选择声音
  NSString *erasePath = [[NSBundle mainBundle] pathForResource:@"Erase" ofType:@"caf"];
     
  NSString *selectPath = [[NSBundle mainBundle] pathForResource:@"Select" ofType:@"caf"];
  
  ///! 根据路径 加载声音
  erasingSound = [[SoundEffect alloc] initWithContentsOfFile:erasePath];
    
  selectSound = [[SoundEffect alloc] initWithContentsOfFile:selectPath];

  
  
}

- (void)createSegmented {
  
  UIImage *redImag = [[UIImage imageNamed:@"Red"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  
   
  UIImage *yellowImag = [[UIImage imageNamed:@"Yellow"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
   
  UIImage *greenImag =[[UIImage imageNamed:@"Green"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
   
  UIImage *blueImag = [[UIImage imageNamed:@"Blue"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

  NSArray *selectColorImagArr = @[redImag,yellowImag,greenImag,blueImag];

  UISegmentedControl *segmentedControl = [[UISegmentedControl alloc]initWithItems:selectColorImagArr];
  
  CGRect rect = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(rect.origin.x + kLeftMargin, rect.size.height - kPaletteHeight - kTopMargin, rect.size.width - (kLeftMargin + kRightMargin), kPaletteHeight);
  
  segmentedControl.frame = frame;

  [segmentedControl addTarget:self action:@selector(changBrushColor:) forControlEvents:UIControlEventValueChanged];
 
  segmentedControl.tintColor = [UIColor darkGrayColor];
    segmentedControl.selectedSegmentIndex = 2;
    
    
  [self.view addSubview:segmentedControl];
  

  
}

//！改变画笔颜色
- (void)changBrushColor:(id)sender {
    
  NSLog(@"修改画笔颜色");
  
  ///! 播放 选择声音
  [selectSound play];

  ///！ 定义一个 新的画笔颜色
  CGColorRef color = [UIColor colorWithHue:(CGFloat)[sender selectedSegmentIndex] / (CGFloat)kPaletteSize saturation:kSaturation brightness:kBrightness alpha:1.0].CGColor;

  ///! 获取颜色组件
  const CGFloat *components = CGColorGetComponents(color);

  //! 将颜色组件 设置 新的画笔颜色
  [(BaseView *)self.view setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
}

//！ 擦除
- (IBAction)earse:(id)sender {
  
  ///! 判断时间间隔，避免连续点击
  if (CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval) {
   
    NSLog(@"清除屏幕");

    ///! 播放 清除 声音
    [erasingSound play];

    ///! 调用 画笔 清除方法
    [(BaseView *)self.view erase];
    
    //保存 当前清除时间 到 lastTime
    lastTime = CFAbsoluteTimeGetCurrent();
    
  }
  
  
    
}



@end
