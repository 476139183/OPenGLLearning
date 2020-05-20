
//! 外界传递过来的值，可更改。
//! 顶点
attribute vec4 position; //有多少个顶点，会传递多少次
//! 颜色
attribute vec4 positionColor; //主要是通过顶点着色器 传递给 片元着色器

//! 两个变换矩阵 投影矩阵 模型视图矩阵,外界传递过来，提供给可编程管线使用,只能使用 不可更改
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

//! 共享数据,内部赋值，进行传递
varying lowp vec4 varyColor; ///! 获取颜色 赋值，

void main () {
  
  varyColor = positionColor;
  
  vec4 vPos;
  
  vPos = projectionMatrix * modelViewMatrix * position;
  
  
  gl_Position = vPos;
  
  
  
}
