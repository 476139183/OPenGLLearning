
/*顶点位置
 */
attribute vec4 position;
// 纹理坐标
attribute vec2 inputTextureCoordinate;
//纹理坐标->fragment
varying lowp vec2 textureCoordinate;

void main(void) {
  
    textureCoordinate = inputTextureCoordinate;

    gl_Position = position;
}

