
//! 
varying lowp vec4 color;

///！ 获取纹理
uniform sampler2D texture;

void main () {
  
  ///! 将颜色和纹理组合 相乘
  gl_FragColor = color * texture2D(texture,gl_PointCoord);
  
}
