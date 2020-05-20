
//！ 饱和度片元着色器

//! 纹理坐标
varying lowp vec2 textureCoordinate;
//! 图片纹理
uniform sampler2D inputImageTexture;
//! 饱和度
uniform lowp float saturation;

//!--------------------

//! 亮度加权，亮度值
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main() {
   
  //! 纹素，通过 texture2D 转化得到，参数1:纹理图片，参数2：纹理坐标
  lowp vec4 source = texture2D(inputImageTexture, textureCoordinate);
   
  //! 亮度加权，让RGB添加一个默认亮度值 亮度=RGB * 亮度加权值
  //! dot 点乘
  lowp float luminance = dot(source.rgb, luminanceWeighting);
  //! 将亮度值变成向量
  lowp vec3 greyScaleColor = vec3(luminance,0,0);

  /*!设置片元颜色
   * genType mix(genType x,genType y,genType a)
   * 函数返回线性X，Y
   * 计算公式：x.(1-a)+y.a
   * 这里传入 亮度向量，纹素RGB 饱和度 得到一个新的RGB值，以及原有的透明度 source.w 组成 4维向量，RGBA
   */
  gl_FragColor = vec4(mix(greyScaleColor, source.rgb, saturation), source.w);
  
}
