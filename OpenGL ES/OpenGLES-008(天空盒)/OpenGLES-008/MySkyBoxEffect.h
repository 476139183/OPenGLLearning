//
//  MySkyBoxEffect.h
//  OpenGLES-008
//  自定义 一个 简单的Effect
//  Created by 段雨田 on 2020/5/14.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

//GLKNamedEffect 提供基于着色器的OpenGL渲染效果的对象的标准接口
@interface MySkyBoxEffect : NSObject<GLKNamedEffect>

@property (nonatomic, assign) GLKVector3 center;
@property (nonatomic, assign) GLfloat xSize;
@property (nonatomic, assign) GLfloat ySize;
@property (nonatomic, assign) GLfloat zSize;
//! 纹理
@property (nonatomic, strong, readonly) GLKEffectPropertyTexture *textureCubeMap;
//! 变换
@property (nonatomic, strong, readonly) GLKEffectPropertyTransform *transform;

//! 准备绘制
- (void)prepareToDraw;
//! 绘制
- (void)draw;

@end
