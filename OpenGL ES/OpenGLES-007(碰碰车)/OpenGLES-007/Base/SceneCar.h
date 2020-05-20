//
//  SceneCar.h
//  OpenGLES-007
//
//  Created by 段雨田 on 2020/5/13.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "SceneCarModel.h"

@protocol SceneCarControllerProtocol

- (NSTimeInterval)timeSinceLastUpdate;
//! get方法
- (SceneAxisAllignedBoundingBox)rinkBoundingBox;
//! 所有的汽车
- (NSArray *)cars;

@end

@interface SceneCar : NSObject

@property (nonatomic, assign) long mCarID;

@property (nonatomic, strong) SceneModel *model;

@property (nonatomic, assign) GLKVector3 position;

@property (nonatomic, assign) GLKVector3 nextPosition;

//速度
@property (nonatomic, assign) GLKVector3 velocity;

//偏航弧度
@property (nonatomic, assign) GLfloat yawRadians;

//目标偏航弧度
@property (nonatomic, assign) GLfloat targetYawRadians;

//颜色
@property (nonatomic, assign) GLKVector4 color;

//半径
@property (nonatomic, assign) GLfloat radius;


- (instancetype)initWithModel:(SceneModel *)aModel
                     position:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        color:(GLKVector4)aColor;

- (void)updateWithController:(id<SceneCarControllerProtocol>)controller;

- (void)drawWithBaseEffect:(GLKBaseEffect *)anEffect;

+ (long)getBounceCount;

- (void)onSpeedChange:(BOOL)slow;

@end

GLfloat SceneScalarFastLowPassFilter(NSTimeInterval timeSinceLastUpdate,GLfloat target,GLfloat current);

GLfloat SceneScalarSlowLowPassFilter(NSTimeInterval timeSinceLastUpdate, GLfloat target,GLfloat current);

GLKVector3 SceneVector3FastLowPassFilter(NSTimeInterval timeSinceLastUpdate, GLKVector3 target,GLKVector3 current);

GLKVector3 SceneVector3SlowLowPassFilter(NSTimeInterval timeSinceLastUpdate,GLKVector3 target,GLKVector3 current);



