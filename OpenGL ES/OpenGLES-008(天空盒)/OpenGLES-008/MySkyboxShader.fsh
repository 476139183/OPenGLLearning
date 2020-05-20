//MySkyboxShader.fsh
//fragment Shader


//! MVP矩阵
uniform highp mat4 u_mvpMatrix;

//! 纹理的立方体贴图
uniform samplerCube u_unitCube[1];

///! 纹理坐标
varying lowp vec3 v_texCoord[1];


void main () {
  
  /* 每一个像素点的颜色
   * textureCube(sampler,p)
   * sampler采样的纹理
   * p 纹理被采样的坐标
   */
  gl_FragColor = textureCube(u_unitCube[0], v_texCoord[0]);
  
  
  
}
