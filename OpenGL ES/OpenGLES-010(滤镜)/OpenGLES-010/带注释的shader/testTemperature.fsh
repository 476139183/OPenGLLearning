//！ 色温片元着色器

//！ 纹理坐标
varying lowp vec2 textureCoordinate;

//! 纹理
uniform sampler2D inputImageTexture;
//! 色温值
uniform lowp float temperature;

//! 色温过滤器
const lowp vec3 warmFilter = vec3(0.93, 0.54, 0.0);
//! RGB -> YIQ 这样才有 色温，和饱和度
const mediump mat3 RGBtoYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311);
//! YIQ -> RBG
const mediump mat3 YIQtoRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702);

void main() {
  
  //! 纹素-> 把纹理按照像素一个一个拿出来
  lowp vec4 source = texture2D(inputImageTexture, textureCoordinate);
  //! 将source的RGB 转为YIQ
  mediump vec3 yiq = RGBtoYIQ * source.rgb;
  /*!
   * clamp(x,minVal,maxVal) 设置最大最小 进行区间比较，返回合理值
   * 也就是返回值，在[-0.5226,0.5226] 之间
   *
   */
  yiq.b = clamp(yiq.b, -0.5226, 0.5226);
  
  //! 最新的RGB
  lowp vec3 rgb = YIQtoRGB * yiq;
  
  //! 调节色温
  lowp float A = (rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r)));
  
  lowp float B = (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g)));
  
  lowp float C =  (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b)));
  
  lowp vec3 processed = vec3(A,B,C);
  //！  混合颜色
  gl_FragColor = vec4(mix(rgb, processed, temperature), source.a);
  
}
