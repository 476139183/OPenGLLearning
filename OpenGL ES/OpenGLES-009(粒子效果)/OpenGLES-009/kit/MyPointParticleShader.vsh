
//! 这些数据，每一个粒子不一样
//! 顶点
attribute vec3 a_emissionPosition;
//! 速度
attribute vec3 a_emissionVelocity;
//! 发射力
attribute vec3 a_emissionForce;
//! 大小
attribute vec2 a_size;
//! 发射时间/销毁时间
attribute vec2 a_emissionAndDeathTimes;

//！固定的的数据
//! MVP 变换矩阵
uniform highp mat4 u_mvpMatrix;
//！纹理
uniform sampler2D u_samplers2D[1];
//! 地球引力 g
uniform highp vec3 u_gravity;
//! 当前时间
uniform highp float u_elapsedSeconds;

//!--------------------
/// 粒子透明度
varying lowp float v_particleOpacity;

void main()
{
  
  //!  流逝时间=当前时间-发射时间
  highp float elaspedTime = u_elapsedSeconds -a_emissionAndDeathTimes.x;
  
  /*! 质量假设为1.0，那么加速度=力
   * v = v0+at
   *  v：当前速度，v0：初速度，a：加速度，t：时间
   */
  highp vec3 veloctity = a_emissionVelocity + ((a_emissionForce + u_gravity) * elaspedTime);
  
  /* 求距离
   * s = s0 + 0.5 * (v0+v) * t
   * s：当前位置，s0初始位置，
   */
  highp vec3 untransformedPosition = a_emissionPosition + 0.5 * (a_emissionVelocity+veloctity)*elaspedTime;
    
  //! 得出点的位置
  gl_Position = u_mvpMatrix * vec4(untransformedPosition,1.0);
  //! 标准化得出点的大小
  gl_PointSize = a_size.x / gl_Position.w;
  
  //! 消失时间: 影响粒子的透明度
  v_particleOpacity = max(0.0, min(1.0,(a_emissionAndDeathTimes.y - u_elapsedSeconds) / max(a_size.y, 0.00001)));
  

}

