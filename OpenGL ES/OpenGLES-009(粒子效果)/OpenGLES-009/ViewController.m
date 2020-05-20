//
//  ViewController.m
//  OpenGLES-009
//  https://www.jianshu.com/p/6ef008dbfa46
//  Created by 段雨田 on 2020/5/15.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "ViewController.h"
#import "MyVertexAttribArrayBuffer.h"
#import "MyPointParticleEffect.h"

@interface ViewController ()

//上下文
@property (nonatomic , strong) EAGLContext* mContext;

//管理并且绘制所有的粒子对象
@property (strong, nonatomic) MyPointParticleEffect *particleEffect;

@property (assign, nonatomic) NSTimeInterval autoSpawnDelta;
@property (assign, nonatomic) NSTimeInterval lastSpawnTime;

@property (assign, nonatomic) NSInteger currentEmitterIndex;
@property (strong, nonatomic) NSArray *emitterBlocks;

//粒子纹理对象
@property (strong, nonatomic) GLKTextureInfo *ballParticleTexture;

@end

@implementation ViewController

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  //! 新建openGL ES 上下文
  _mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  
  //!
  GLKView *view = (GLKView *)self.view;
  view.context = _mContext;
  view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
  view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  [EAGLContext setCurrentContext:_mContext];
  
  //! 3. 纹理路径
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"ball" ofType:@"png"];
  
  if (path == nil) {
    return;
  }
  
  //! 加载纹理，因为是圆形的，无所谓读取顺序
  self.ballParticleTexture = [GLKTextureLoader textureWithContentsOfFile:path options:nil error:nil];
  
  //! 粒子对象
  self.particleEffect = [[MyPointParticleEffect alloc] init];
  self.particleEffect.texture2d0.name = self.ballParticleTexture.name;
  self.particleEffect.texture2d0.target = self.ballParticleTexture.target;
  
  //! 开启深度 和混合
  glEnable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);
  //! 混合因子
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
  //! 4中不同的效果
  void (^blockA)(void) = ^{
    //！创建一个
    self.autoSpawnDelta = 0.5;
    
    self.particleEffect.gravity = kDefaultGravity;
    
    //X轴上随机速度
    float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;

    /* 添加粒子
     Position:出发位置
     velocity:速度
     force:抛物线
     size:大小
     lifeSpanSeconds:耗时
     fadeDurationSeconds:渐逝时间
     */
   
    [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.9f)
                                      velocity:GLKVector3Make(randomXVelocity, 1.0f, -1.0f)
                                         force:GLKVector3Make(0.0f, 9.0f, 0.0f)
                                          size:8.0f
                               lifeSpanSeconds:3.2f
                           fadeDurationSeconds:0.5f];
  
  };
  
  void (^blockB)(void) = ^{
    //！  同时创建50个
    self.autoSpawnDelta = 0.05f;
         
    //重力
    self.particleEffect.gravity = GLKVector3Make(0.0f,0.5f, 0.0f);
          
    //一次创建多少个粒子
    int n = 50;
          
    for (int i = 0; i < n; i++) {
             
      //X轴速度
      float randomXVelocity = -0.1f + 0.2f *(float)random() / (float)RAND_MAX;
             
      //Y轴速度
      float randomZVelocity = 0.1f + 0.2f * (float)random() / (float)RAND_MAX;
              
      //计算速度与方向
      GLKVector3 velocity = GLKVector3Make(randomXVelocity,
                                           0.0,
                                           randomZVelocity);
             
      [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, -0.5f, 0.0f)
                                        velocity:velocity
                                           force:GLKVector3Make(0.0f, 0.0f, 0.0f)
                                            size:16.0f
                                 lifeSpanSeconds:2.2f
                             fadeDurationSeconds:3.0f];
    }
    
  };
  
  void (^blockC)(void) = ^{
    //！ 圆形扩散
    self.autoSpawnDelta = 0.5f;
          
    //重力
    self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
         
    int n = 100;
        
    for (int i = 0; i < n; i++) {
             
      //X,Y,Z速度
      float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
      float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
      float randomZVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
              
      //计算速度与方向
      GLKVector3 velocity = GLKVector3Make(randomXVelocity,
                                           randomYVelocity,
                                           randomZVelocity);
      
             
      [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
                                        velocity:velocity
                                           force:GLKVector3Make(0.0f, 0.0f, 0.0f)
                                            size:4.0f
                                 lifeSpanSeconds:3.2f
                             fadeDurationSeconds:0.5f];
         
    }
    
  };
  
  void (^blockD)(void) = ^{
    //！ 圆圈，速度一样，方向不一样
    self.autoSpawnDelta = 3.2f;
         
    //重力
    self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
         
         
    int n = 100;
    for (int i = 0; i < n; i++) {
             
      //X,Y速度
      float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
      float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
             
      //GLKVector3Normalize 计算法向量
      //计算速度与方向
      GLKVector3 velocity = GLKVector3Normalize(GLKVector3Make(
                                                               randomXVelocity,
                                                               randomYVelocity,
                                                               0.0f));
             
            
      [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
                                        velocity:velocity
                                           force:GLKVector3MultiplyScalar(velocity, -1.5f)
                                            size:4.0f
                                 lifeSpanSeconds:3.2f
                             fadeDurationSeconds:0.1f];
       
    }
    
  };
  
  //将4种不同效果的BLOCK块存储到数组中
  self.emitterBlocks = @[[blockA copy],[blockB copy],[blockC copy],[blockD copy]];
  
  //纵横比
  float aspect = CGRectGetWidth(self.view.bounds) / CGRectGetHeight(self.view.bounds);
  
  //设置投影方式\模型视图变换矩阵
  [self preparePointOfViewWithAspectRatio:aspect];
  
}

//MVP矩阵
- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
  
  ///！ 设置投影方式
  self.particleEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0f), aspectRatio, 0.1, 20.0f);
  
  //!
  self.particleEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 1.0f,
                                                                       0.0f, 0.0f, 0.0f,
                                                                       0.0f, 1.0f, 0.0f);
  
  
  
}

//更新
- (void)update
{
    
   
  //时间间隔
  NSTimeInterval timeElapsed = self.timeSinceFirstResume;
  
  /*
  //上一次更新时间
  NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
  //上一次绘制的时间
  NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
  //第一次恢复时间
  NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
  //上一次恢复时间
  NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);
  */
  //消耗时间
  self.particleEffect.elapsedSeconds = timeElapsed;
  
  //动画时间 < 当前时间与上一次更新时间
    
  if(self.autoSpawnDelta < (timeElapsed - self.lastSpawnTime)) {
        
    //更新上一次更新时间
    self.lastSpawnTime = timeElapsed;
        
    //获取当前选择的block
    void(^emitterBlock)(void) = [self.emitterBlocks objectAtIndex: self.currentEmitterIndex];
         
    //执行block
    emitterBlock();
    
  }
  
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
   
  glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
  
  glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
  //! 准备绘制
  [self.particleEffect prepareToDraw];
  //! 绘制
  [self.particleEffect draw];
    
}

- (IBAction)ChangeIndex:(UISegmentedControl *)sender {
   //选择不同的效果
  self.currentEmitterIndex = [sender selectedSegmentIndex];
}


@end
