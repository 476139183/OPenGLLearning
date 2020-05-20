//
//  SceneMesh.m
//  OpenGLES-007
//
//  Created by 段雨田 on 2020/5/13.
//  Copyright © 2020 段雨田. All rights reserved.
//

#import "SceneMesh.h"
#import "AGLKVertexAttribArrayBuffer.h"

@interface SceneMesh()

@property (nonatomic, strong) AGLKVertexAttribArrayBuffer *vertexAttributeBuffer;
//索引bufferID
@property (nonatomic, assign) GLuint indexBufferID;
//顶点数据
@property (nonatomic, strong) NSData *vertexData;
//索引数据
@property (nonatomic, strong) NSData *indexData;


@end

@implementation SceneMesh


#pragma mark - init
- (instancetype)initWithVertexAttributeData:(NSData *)vertexAttributes
                                  indexData:(NSData *)indices {
    
  self = [super init];
  if (self) {
    self.vertexData = vertexAttributes;
    self.indexData = indices;
  }
  return self;
}


- (instancetype)initWithPositionCoords:(const GLfloat *)somePositions
                          normalCoords:(const GLfloat *)someNormals
                            texCoords0:(const GLfloat *)someTexCoords0
                     numberOfPositions:(size_t)countPositions
                               indices:(const GLushort *)someIndices //索引
                       numberOfIndices:(size_t)countIndices {
  
  NSParameterAssert(somePositions != NULL);
  NSParameterAssert(someNormals != NULL);
  NSParameterAssert(countPositions > 0);
  
  NSMutableData *vertexAttributesData = [[NSMutableData alloc]init];
  NSMutableData *indicesData = [[NSMutableData alloc]init];
  
  [indicesData appendBytes:someIndices length:countIndices * sizeof(GLushort)];
  
  //将顶点数据、纹理数据转为二进制
  
  for (size_t i = 0; i < countPositions; i++) {
    
    SceneMeshVertex currentVertex;
      
    //顶点坐标x,y,z
    currentVertex.position.x = somePositions[i * 3 + 0];
    currentVertex.position.y = somePositions[i * 3 + 1];
    currentVertex.position.z = somePositions[i * 3 + 2];
    
    //法线数组
    currentVertex.normal.x = someNormals[i * 3 + 0];
    currentVertex.normal.y = someNormals[i * 3 + 1];
    currentVertex.normal.z = someNormals[i * 3 + 2];
      
    //纹理
    if (someTexCoords0 != NULL) {
      currentVertex.texCoords0.s = someTexCoords0[i * 2 + 0];
      currentVertex.texCoords0.t = someTexCoords0[i * 2 + 1];
    } else {
      currentVertex.texCoords0.s = 0.0f;
      currentVertex.texCoords0.t = 0.0f;
    }
      
    [vertexAttributesData appendBytes:&currentVertex length:sizeof(currentVertex)];
      
  }
  
  return [self initWithVertexAttributeData:vertexAttributesData indexData:indicesData];;
}

- (void)prepareToDraw {
    
  if (self.vertexAttributeBuffer == nil & self.vertexData.length > 0) {
    //将顶点数据还有送至GPU中，将数据送至GPU
    self.vertexAttributeBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(SceneMeshVertex) numberOfVertices:(GLsizei)(self.vertexData.length/sizeof(SceneMeshVertex)) bytes:self.vertexData.bytes usage:GL_STATIC_DRAW];
            
    //清空vertexData
    self.vertexData = nil;
  }
   
  if (_indexBufferID == 0 && self.indexData.length > 0) {
    //索引数组还没有缓存
    glGenBuffers(1, &_indexBufferID);
    if (self.indexBufferID != 0) {
      NSLog(@"Failed to generate element arrya buffer");
      return;
    }
        
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.indexBufferID);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, self.indexData.length, self.indexData.bytes, GL_STATIC_DRAW);
        
    //使用完就可以清空了
    self.indexData = nil;
  }
    
  //准备绘制顶点数据
  [self.vertexAttributeBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:offsetof(SceneMeshVertex, position) shouldEnable:YES];
  
  //准备绘制法线数据
  [self.vertexAttributeBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:offsetof(SceneMeshVertex, normal) shouldEnable:YES];
  
  //准备绘制纹理数据
  [self.vertexAttributeBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:offsetof(SceneMeshVertex,texCoords0) shouldEnable:YES];
    
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBufferID);

}

//不使用索引绘制
- (void)drawUnidexedWithMode:(GLenum)mode
            startVertexIndex:(GLint)first
            numberOfVertices:(GLsizei)count {
  [self.vertexAttributeBuffer drawArrayWithMode:mode startVertexIndex:first numberOfVertices:count];
}

//动态分配空间
- (void)makeDynamicAndUpdateWithVertices:(const SceneMeshVertex *)someVerts
                        numberOfVertices:(size_t)count {
   
  NSParameterAssert(someVerts != NULL);
  NSParameterAssert(count > 0);
    
  GLsizei count_t = (GLsizei)count;
    
  if (self.vertexAttributeBuffer == nil) {
        
    self.vertexAttributeBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:sizeof(SceneMeshVertex) numberOfVertices:count_t bytes:someVerts usage:GL_DYNAMIC_DRAW];
        
  } else {
      
    [self.vertexAttributeBuffer reinitWithAttribStride:sizeof(SceneMeshVertex) numberOfVertices:count_t bytes:someVerts];
        
  }
  
}


@end
