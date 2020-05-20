
//! 顶点着色器


//！ 顶点
attribute vec4 inVertex;

//! 模型视图 投影矩阵
uniform mat4 MVP;

//! 点的大小
uniform float pointSize;

//! 顶点颜色
uniform lowp vec4 vertexColor;

//! 将顶点颜色 传递给 片元着色器
varying lowp vec4 color;


void main() {
  
  //! 顶点计算 = 矩阵*顶点
  gl_Position = MVP * inVertex;
  
  ///! 修改顶点大小
  gl_PointSize = pointSize;
  
  ///! 因为顶点着色器不处理颜色，将颜色 vertexColor 赋值给 通用数据 color
  color = vertexColor;
  
}
