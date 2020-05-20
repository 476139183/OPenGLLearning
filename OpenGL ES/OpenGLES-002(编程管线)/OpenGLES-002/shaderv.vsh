
//！ 顶点着色器

///! 顶点数据
attribute vec4 position;

///! 纹理
attribute vec2 textCoordinate;

///! 旋转矩阵
uniform  mat4 rotateMatrix;

///! 我们需要传递纹理数据
varying lowp vec2 varyTextCoord;


///! 函数入口
void main () {
  
  //!将纹理textCoordinate 通过 varyTextCoord 传递到片元着色器，
  varyTextCoord = textCoordinate;
  
  vec4 vPos = position;
  
  ///! 将顶点 应用旋转变换
  vPos = vPos * rotateMatrix;
  
  ///! 内建变量 gl_Position,必须赋值
  gl_Position = vPos;
  
  
  
}


