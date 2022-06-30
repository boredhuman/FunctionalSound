import 'dart:html';
import 'dart:math';
import 'dart:web_gl';
import '../main.dart';

class FontTexture {

  CanvasElement canvasElement;
  Texture? glTexture;
  List<TextMetrics> textMetricsList = [];
  int width = 512;
  int height = 512;
  List<int> textBoxes = [];

  FontTexture() : canvasElement = document.createElement("canvas") as CanvasElement {
    //CanvasElement mainCanvas = document.getElementById("canvas") as CanvasElement;
    //document.body!.insertBefore(canvasElement, mainCanvas);
    CanvasRenderingContext2D canvasRenderer = canvasElement.getContext("2d") as CanvasRenderingContext2D;

    canvasElement.width = width;
    canvasElement.height = height;
    setFont(32, canvasRenderer, "monospace");
    //canvasRenderer.setFillColorRgb(0, 0, 0, 255);
    canvasRenderer.setFillColorRgb(0, 0, 0, 0);
    canvasRenderer.fillRect(0, 0, width, height);
    canvasRenderer.setFillColorRgb(255, 255, 255, 255);

    int wid = width ~/ 16;
    for (int i = 0; i < 256; i++) {
      String letter = String.fromCharCode(i);
      TextMetrics textMetrics = canvasRenderer.measureText(letter);
      textMetricsList.add(textMetrics);
      int x = i % 16 * 32 + (wid ~/ 2) - (textMetrics.width! ~/ 2);
      int y = i ~/ 16 * 32 + textMetrics.fontBoundingBoxAscent!.toInt();
      // canvasRenderer.beginPath();
      // canvasRenderer.strokeStyle = "red";
      // canvasRenderer.lineWidth = 1;
      textBoxes.addAll([x, y - 25, 32, 32]);
      // canvasRenderer.rect(x, y - 25, 32, 32);
      // canvasRenderer.stroke();
      canvasRenderer.fillText(letter, x, y);
    }

    upload();
  }

  void setFont(int maxHeight, CanvasRenderingContext2D renderer, String fontName) {
    double height;
    int i = 0;
    do {
      renderer.font = "${maxHeight - i}px $fontName";
      height = getMaxHeight(renderer);
      i++;
    } while (height > maxHeight);
  }
  
  double getMaxHeight(CanvasRenderingContext2D renderer) {
    double ascent = 0;
    double decent = 0;
    for (int i = 0; i < 256; i++) {
      String letter = String.fromCharCode(i);
      TextMetrics textMetrics = renderer.measureText(letter);
      ascent = max(textMetrics.fontBoundingBoxAscent!.toDouble(), ascent);
      decent = max(textMetrics.fontBoundingBoxDescent!.toDouble(), decent);
    }
    return ascent + decent;
  }

  void upload() {
    glTexture = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, glTexture);
    gl.pixelStorei(WebGL.UNPACK_PREMULTIPLY_ALPHA_WEBGL, 1);

    gl.texImage2D(WebGL.TEXTURE_2D, 0, WebGL.RGBA, WebGL.RGBA, WebGL.UNSIGNED_BYTE, canvasElement);

    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, WebGL.CLAMP_TO_EDGE);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, WebGL.CLAMP_TO_EDGE);
  }

  Texture? getGLTexture() {
    return glTexture;
  }
}