


//！固定的的数据
//! MVP 变换矩阵
uniform highp mat4 u_mvpMatrix;
//！纹理
uniform sampler2D u_samplers2D[1];
//! 地球引力 g
uniform highp vec3 u_gravity;
//! 当前时间
uniform highp float u_elapsedSeconds;

/// 粒子透明度
varying lowp float v_particleOpacity;

void main()
{
  
  //!  获取纹理值 RGBA
  lowp vec4 textureColor = texture2D(u_samplers2D[0],gl_PointCoord);
  
  textureColor.a = textureColor.a * v_particleOpacity;
  
  gl_FragColor = textureColor;
   
}
