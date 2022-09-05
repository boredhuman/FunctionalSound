import 'dart:core';
import 'dart:web_gl';

import 'buffer_builder.dart';
import '../main.dart';
import '../util/mat4.dart';
import 'matrix_stack.dart';
import 'shaders.dart';

drawTriangle(int x1, int y1, int x2, int y2, int x3, int y3, int color) {
  ShaderProgram shader = getPositionShader();

  bufferBuilder.begin(DefaultVertexFormats.position2F);

  bufferBuilder.positionI(x1, y1);
  bufferBuilder.positionI(x2, y2);
  bufferBuilder.positionI(x3, y3);

  bufferBuilder.bind(shader.attributeLocations);

  shader.enableAttributes();
  shader.bind();

  List<double> colors = getColor(color);
  gl.uniform4f(shader.uniformLocations["color"], colors[0], colors[1], colors[2], colors[3]);
  gl.drawArrays(WebGL.TRIANGLES, 0, 3);
}

drawLine(int x1, int y1, int x2, int y2, int color, {int lineWidth = 1}) {
  ShaderProgram shader = getPositionShader();

  bufferBuilder.begin(DefaultVertexFormats.position2F);

  bufferBuilder.positionI(x1, y1);
  bufferBuilder.positionI(x2, y2);

  bufferBuilder.bind(shader.attributeLocations);

  shader.enableAttributes();
  shader.bind();

  List<double> colors = getColor(color);
  gl.uniform4f(shader.uniformLocations["color"], colors[0], colors[1], colors[2], colors[3]);
  gl.lineWidth(lineWidth);

  gl.drawArrays(WebGL.LINES, 0, 2);
}

drawCross(int x, int y, int width, int color) {
  int wid = width ~/ 3;
  int half = width ~/ 2;
  x -= half;
  y -= half;
  // horizontal quad
  drawQuad(x, y + wid * 2, x + width, y + wid, color);
  // vertical quad
  drawQuad(x + wid, y + width, x + wid * 2, y, color);
}

drawRoundedCross(int x, int y, int width, int color) {
  int wid = width ~/ 3;
  int half = width ~/ 2;
  x -= half;
  y -= half;
  // horizontal quad
  drawQuadColor(x, y + wid * 2, x + width, y + wid, color, null, null, null, wid ~/ 2, 2);
  // vertical quad
  drawQuadColor(x + wid, y + width, x + wid * 2, y, color, null, null, null, wid ~/ 2, 2);
}

drawCircle(int x, int y, int radius, int color) {
  int left = x - radius;
  int bottom = y - radius;
  int right = x + radius;
  int top = y + radius;

  drawQuadColor(left, top, right, bottom, color, null, null, null, radius, 3);
}

drawQuadColor(int left, int top, int right, int bottom, int colorLeftBottom, int? colorRightBottom, int? colorLeftTop, int? colorRightTop,
    [int? rounding, int? gradient, int? topColor]) {
  bool doRounding = rounding != null;
  ShaderProgram shader = doRounding ? getPositionColorRoundingShader() : getPositionColorShader();

  colorRightTop = colorRightTop ?? colorLeftBottom;
  colorRightBottom = colorRightBottom ?? colorLeftBottom;
  colorLeftTop = colorLeftTop ?? colorLeftBottom;
  bufferBuilder.begin(DefaultVertexFormats.position2FColor4F);
  bufferBuilder.positionI(left, bottom).colorI(colorLeftBottom);
  bufferBuilder.positionI(right, bottom).colorI(colorRightBottom);
  bufferBuilder.positionI(left, top).colorI(colorLeftTop);
  bufferBuilder.positionI(right, top).colorI(colorRightTop);

  bufferBuilder.bind(shader.attributeLocations);
  shader.enableAttributes();
  shader.bind();

  if (doRounding) {
    gl.uniform1f(shader.uniformLocations["rounding"], rounding);
    gl.uniform1f(shader.uniformLocations["smoothGradient"], gradient ?? 0);
    int width = right - left;
    int height = top - bottom;
    int midPointX = left + width ~/ 2;
    int midPointY = bottom + height ~/ 2;

    // mid point needs to be in view space so do this below to put it into view space
    List<double> transformedMidPoint = MatrixStack.modelViewMatrixStack.getMatrix().transform([midPointX.toDouble(), midPointY.toDouble(), 0, 1]);
    gl.uniform2f(shader.uniformLocations["midPoint"], transformedMidPoint[0], transformedMidPoint[1]);
    gl.uniform2f(shader.uniformLocations["dimensions"], width ~/ (2 * zoom), height ~/ (2 * zoom));
  }
  gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);

  if (topColor != null && doRounding) {
    bufferBuilder.begin(DefaultVertexFormats.position2FColor4F);
    bufferBuilder.positionI(left, top - rounding).colorI(topColor);
    bufferBuilder.positionI(right, top - rounding).colorI(topColor);
    bufferBuilder.positionI(left, top).colorI(topColor);
    bufferBuilder.positionI(right, top).colorI(topColor);

    bufferBuilder.bind(shader.attributeLocations);

    gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);
  }
}

drawQuad(int left, int top, int right, int bottom, int rgba) {
  ShaderProgram positionShader = getPositionShader();

  bufferBuilder.begin(DefaultVertexFormats.position2F);
  bufferBuilder.positionI(left, bottom);
  bufferBuilder.positionI(right, bottom);
  bufferBuilder.positionI(left, top);
  bufferBuilder.positionI(right, top);

  bufferBuilder.bind(positionShader.attributeLocations);
  positionShader.enableAttributes();

  positionShader.bind();

  List<double> color = getColor(rgba);
  gl.uniform4f(positionShader.uniformLocations["color"], color[0], color[1], color[2], color[3]);

  gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, 4);
}

renderFontAtlas(Mat4 projectionMatrix) {
  ShaderProgram shader = getPositionColorTextureShader();

  bufferBuilder.begin(DefaultVertexFormats.position2FColor4FTex2F);
  gl.enable(WebGL.BLEND);
  gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA);
  bufferBuilder.position(100, 100).colorI(0xFF0000FF).texF(0, 1);
  bufferBuilder.position(612, 100).colorI(0xFF0000FF).texF(1, 1);
  bufferBuilder.position(100, 612).colorI(0xFF0000FF).texF(0, 0);
  bufferBuilder.position(612, 612).colorI(0xFF0000FF).texF(1, 0);

  bufferBuilder.bind(shader.attributeLocations);

  shader.enableAttributes();
  shader.bind();

  gl.uniformMatrix4fv(shader.uniformLocations["projectionMatrix"], false, projectionMatrix.getMatrix());
  gl.uniform1i(shader.uniformLocations["texture"], 0);
  gl.bindTexture(WebGL.TEXTURE_2D, fontTexture.glTexture);

  gl.drawArrays(WebGL.TRIANGLE_STRIP, 0, bufferBuilder.vertexCount);
}

drawString(String text, int xPos, int yPos, int color) {
  ShaderProgram shader = getPositionColorTextureShader();

  bufferBuilder.begin(DefaultVertexFormats.position2FColor4FTex2F);
  fontRenderer!.renderString(text, xPos, yPos, color);

  bufferBuilder.bind(shader.attributeLocations);

  shader.enableAttributes();
  shader.bind();

  gl.uniform1i(shader.uniformLocations["texture"], 0);
  gl.bindTexture(WebGL.TEXTURE_2D, fontTexture.glTexture);

  gl.drawArrays(WebGL.TRIANGLES, 0, bufferBuilder.vertexCount);
}

List<double> getColor(int rgba) {
  double red = ((rgba >> 24) & 0xFF) / 255.0;
  double green = ((rgba >> 16) & 0xFF) / 255.0;
  double blue = ((rgba >> 8) & 0xFF) / 255.0;
  double alpha = (rgba & 0xFF) / 255.0;
  return [red, green, blue, alpha];
}
