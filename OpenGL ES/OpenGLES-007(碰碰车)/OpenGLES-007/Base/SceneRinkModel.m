//
//  SceneRinkModel.m
//  OpenGLES-007
//
//  Created by 段雨田 on 2020/5/13.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "SceneRinkModel.h"

#import "SceneMesh.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "bumperRink.h"

@implementation SceneRinkModel

- (instancetype)init {
   
  SceneMesh *rinkMesh = [[SceneMesh alloc]initWithPositionCoords:bumperRinkVerts
                                                    normalCoords:bumperRinkNormals texCoords0:NULL
                                               numberOfPositions:bumperRinkNumVerts
                                                         indices:NULL
                                                 numberOfIndices:0];
    
  self = [super initWithName:@"bumberRink" mesh:rinkMesh numberOfVertices:bumperRinkNumVerts];
   
  if (self) {
    [self updateAlignedBoundingBoxForVertices:bumperRinkVerts count:bumperRinkNumVerts];
  }
   
  return self;
}

@end
