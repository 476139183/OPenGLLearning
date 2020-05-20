//
//  MyPointParticleEffect.h
//  OpenGLES-009
//
//  Created by 段雨田 on 2020/5/15.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

extern const GLKVector3 kDefaultGravity;


@interface MyPointParticleEffect : NSObject

// 默认重力
@property(nonatomic,assign) GLKVector3 gravity;

// 耗时
@property(nonatomic,assign)GLfloat elapsedSeconds;

// 纹理
@property (strong, nonatomic, readonly)GLKEffectPropertyTexture *texture2d0;

// 变换
@property (strong, nonatomic, readonly) GLKEffectPropertyTransform *transform;


//添加粒子
/*
 aPosition:位置
 aVelocity:速度
 aForce:重力
 aSize:大小
 aSpan:跨度
 aDuration:时长
 */
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;

//准备绘制
- (void)prepareToDraw;

//！绘制
- (void)draw;

@end


