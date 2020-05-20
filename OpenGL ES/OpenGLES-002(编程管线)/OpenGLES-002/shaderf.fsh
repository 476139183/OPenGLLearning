
//! GLSL 语法:着色器程序语言，编写 可编程管线
/*
 
 三种修饰类型: uniform,attribute,varying
 

 ------------------------------------------- Uniform
 
 uniform: 从外部程序 传递过来 给 着色器(Vertex Shader,fragment Shader)的变量
 A. 由 application 通过 函数 glUniform**() 函数赋值 的
 B. 在 着色器 内部中，类似 C 语言的 const，它不能被 着色器 修改
 
 注意：uniform 变量，着色器只能用，不能改！

 例如：修饰 变换矩阵，
 投影矩阵 uniform mat4 viewProjectMatix
 视图变换矩阵 uniform mat4 viewMatix
 光源位置 uniform mat4 lightPosition
 
 ------------------------------------------- attribute

 只能在顶点着色器使用，在片元着色器使用毫无意义，所以不能在 片元着色器 声明 attribute 变量，也不能被 片元着色器使用
 它一般是 修饰顶点坐标，法线，纹理坐标，顶点颜色
 
 注意： attribute 只能在 Vertex Shader 中使用，不能在 fragment Shader 中使用
 
 例如：
 位置(x,y,z,w) attribute vec4 a_position
 纹理颜色  attribute vec2 a_texCoord0
 
 
 
 ------------------------------------------- varying

 在 顶点着色器 和 片元着色器 之间 传递数据的。双方 用 varying 修饰的变量，如果变量名一致，则数据互通
 
 例如：在 顶点着色器 和 片元着色器 都有如下变量
 
  纹理颜色 varying vec2 v_texCoord
 
 
 */




///! 片元着色器

///! 我们需要传递纹理数据，
varying lowp vec2 varyTextCoord;

// 2D 纹理
uniform sampler2D colorMap;

void main () {
  
  //! 内建变量 gl_FragColor，必须赋值
  gl_FragColor = texture2D(colorMap,varyTextCoord);
  
  
}
