import 'dart:typed_data';
import 'dart:web_gl';

import '../main.dart';
import 'render_util.dart';

class VertexElement {
  int size;
  int sizeBytes;
  int type;
  bool normalized;

  VertexElement(this.size, this.sizeBytes, this.type, this.normalized);
}

class VertexFormat {
  List<VertexElement> elements = [];
  int stride = 0;

  VertexFormat addVertexElement(VertexElement element) {
    elements.add(element);

    stride += element.sizeBytes;
    return this;
  }

  void setupAttributes(List<int> attributeLocations) {
    int offset = 0;
    for (int i = 0; i < attributeLocations.length; i++) {
      int attributeLocation = attributeLocations[i];
      VertexElement vertexElement = elements[i];
      gl.vertexAttribPointer(attributeLocation, vertexElement.size, vertexElement.type, vertexElement.normalized, stride, offset);
      offset += vertexElement.sizeBytes;
    }
  }
}

class DefaultVertexFormats {
  static final VertexElement position2FE = VertexElement(2, 8, WebGL.FLOAT, false);
  static final VertexElement color4FE = VertexElement(4, 16, WebGL.FLOAT, false);
  static final VertexFormat position2F = VertexFormat().addVertexElement(position2FE);
  static final VertexFormat position2FColor4F = VertexFormat().addVertexElement(position2FE).addVertexElement(color4FE);
  static final VertexFormat position2FColor4FTex2F = VertexFormat().addVertexElement(position2FE).addVertexElement(color4FE).addVertexElement(position2FE);
}

class BufferBuilder {
  List<double> data = [];
  Buffer vbo;
  VertexFormat? vertexFormat;
  int vertexCount = 0;

  BufferBuilder() : vbo = gl.createBuffer();

  void begin(VertexFormat vertexFormat) {
    this.vertexFormat = vertexFormat;
  }

  BufferBuilder positionI(int x, int y) {
    position(x.toDouble(), y.toDouble());
    return this;
  }

  BufferBuilder texF(double u, double v) {
    data.add(u);
    data.add(v);
    return this;
  }

  BufferBuilder texI(int u, int v) {
    data.add(u.toDouble());
    data.add(v.toDouble());
    return this;
  }

  BufferBuilder position(double x, double y) {
    data.add(x);
    data.add(y);
    return this;
  }

  BufferBuilder colorI(int rgba) {
    List<double> colors = getColor(rgba);
    color(colors[0], colors[1], colors[2], colors[3]);
    return this;
  }

  void color(double red, double green, double blue, double alpha) {
    data.add(red);
    data.add(green);
    data.add(blue);
    data.add(alpha);
  }

  void clear() {
    data.clear();
  }

  void bind(List<int> attributeLocations) {
    int strideFloats = vertexFormat!.stride ~/ 4;
    vertexCount = data.length ~/ strideFloats;
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vbo);
    gl.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(data), WebGL.DYNAMIC_DRAW);
    clear();
    vertexFormat!.setupAttributes(attributeLocations);
  }
}