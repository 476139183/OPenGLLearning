//
//  SceneModel.h
//  OpenGLES-007
//
//  Created by 段雨田 on 2020/5/13.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@class AGLKVertexAttribArrayBuffer;
@class SceneMesh;

//现场包围盒
typedef struct {
  GLKVector3 min;
  GLKVector3 max;
} SceneAxisAllignedBoundingBox;

@interface SceneModel : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) SceneAxisAllignedBoundingBox axisAlignedBoundingBox;


- (instancetype)initWithName:(NSString *)aName
                        mesh:(SceneMesh *)aMesh
            numberOfVertices:(GLsizei)aCount;

//绘制
- (void)draw;

//顶点数据改变后，重新计算边界
- (void)updateAlignedBoundingBoxForVertices:(float *)verts count:(int)aCount;


/*
 * 汽车模型 和 场地 模型，在绘制上 逻辑一致，只不过模型数据有区别而已，所以可以共用一个父类，统一处理绘制
 *
 */

@end


