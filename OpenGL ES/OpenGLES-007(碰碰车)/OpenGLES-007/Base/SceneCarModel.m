//
//  SceneCarModel.m
//  OpenGLES-007
//
//  Created by 段雨田 on 2020/5/13.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "SceneCarModel.h"

#import "SceneMesh.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "bumperCar.h"

@implementation SceneCarModel

- (instancetype)init {
   
  SceneMesh *carMesh = [[SceneMesh alloc] initWithPositionCoords:bumperCarVerts normalCoords:bumperCarNormals texCoords0:NULL numberOfPositions:bumperCarNumVerts indices:NULL numberOfIndices:0];
   
  self = [super initWithName:@"bumberCar" mesh:carMesh numberOfVertices:bumperCarNumVerts];
      
  if(self) {
    //顶点数据改变后，重新计算边界
    [self updateAlignedBoundingBoxForVertices:bumperCarVerts count:bumperCarNumVerts];
  }
   
  return self;
}

@end

