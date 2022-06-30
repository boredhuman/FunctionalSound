import 'dart:web_gl';
import '../main.dart';
import '../util/util.dart';
import 'matrix_stack.dart';

String positionColorVertexShader = "attribute vec2 position;"
    "attribute vec4 color;"
    ""
    "uniform mat4 projectionMatrix;"
    "uniform mat4 modelViewMatrix;"
    ""
    "varying vec4 outColor;"
    ""
    "void main() {"
    "  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 0.0, 1.0);"
    "  outColor = color;"
    "}";

String positionColorFragmentShader = "precision mediump float;"
    ""
    "varying vec4 outColor;"
    ""
    "void main() {"
    "  gl_FragColor = outColor;"
    "}";

String positionColorRoundingFragmentShader = "precision mediump float;"
    ""
    "varying vec4 outColor;"
    ""
    "uniform vec2 midPoint;"
    "uniform vec2 dimensions;"
    "uniform float rounding;"
    "uniform float smoothGradient;"
    ""
    "void main() {"
    "  vec2 offset = abs(gl_FragCoord.xy - midPoint);"
    "  vec2 dif = offset - (dimensions - rounding);"
    "  float sdf = length(max(dif, 0.0));"
    "  if (sdf < rounding) {"
    "    gl_FragColor = vec4(outColor.rgb, outColor.a * smoothstep(rounding, rounding - smoothGradient, sdf));"
    "  }"
    "}";

String positionColorLineSegmentFragmentShader = """precision mediump float;
    
    varying vec4 outColor;
    
    uniform vec2 pointA;
    uniform vec2 pointB;
    uniform float radius;
    
    void main() {
      vec2 ab = pointB - A;
      float dSq = ab.x * ab.x + ab.y * ab.y;
      float dotP = dot(gl_FragCoord.xy - A, B - A) / dSq;
      float h = min(1.0, max(0.0, dotP));
      float d = length(gl_FragCoord.xy - A - h * (B - A));
      if (d < radius) {
        gl_FragColor = vec4(outColor.rgb, outColor.a * smoothstep(radius, radius - 1.0, d));
      }
    }""";

String positionVertexShader = "attribute vec2 position;"
    ""
    "uniform mat4 projectionMatrix;"
    "uniform mat4 modelViewMatrix;"
    ""
    "void main() {"
    "  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 0.0, 1.0);"
    "}";

String positionFragmentShader = "precision mediump float;"
    ""
    "uniform vec4 color;"
    ""
    "void main() {"
    "  gl_FragColor = color;"
    "}";

String positionColorTextureVertexShader = "attribute vec2 position;"
    "attribute vec4 color;"
    "attribute vec2 texCoord;"
    ""
    "uniform mat4 projectionMatrix;"
    "uniform mat4 modelViewMatrix;"
    ""
    "varying vec2 outTexCoord;"
    "varying vec4 outColor;"
    ""
    "void main() {"
    "  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 0.0, 1.0);"
    "  outTexCoord = texCoord;"
    "  outColor = color;"
    "}";

String positionColorTextureFragmentShader = "precision mediump float;"
    ""
    "varying vec2 outTexCoord;"
    "varying vec4 outColor;"
    ""
    "uniform sampler2D texture;"
    ""
    "void main() {"
    "  vec4 textureColor = texture2D(texture, outTexCoord);"
    "  gl_FragColor = textureColor * outColor;"
    "}";

Program? makeProgram(String vertexSource, String fragmentSource) {
  Shader? vertexShader = loadShader(WebGL.VERTEX_SHADER, vertexSource);
  Shader? fragmentShader = loadShader(WebGL.FRAGMENT_SHADER, fragmentSource);

  Program program = gl.createProgram();

  gl.attachShader(program, vertexShader!);
  gl.attachShader(program, fragmentShader!);
  gl.linkProgram(program);

  if (!(gl.getProgramParameter(program, WebGL.LINK_STATUS) as bool)) {
    consoleLog(gl.getProgramInfoLog(program)!);
    return null;
  }

  return program;
}

Shader? loadShader(int type, String source) {
  Shader shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);

  if (!(gl.getShaderParameter(shader, WebGL.COMPILE_STATUS) as bool)) {
    consoleLog(gl.getShaderInfoLog(shader)!);
    gl.deleteShader(shader);
    return null;
  }
  return shader;
}

ShaderProgram? positionColorTextureShader;

ShaderProgram getPositionColorTextureShader() {
  if (positionColorTextureShader == null) {
    Program? program = makeProgram(positionColorTextureVertexShader, positionColorTextureFragmentShader);
    positionColorTextureShader = ShaderProgram(program!, ["projectionMatrix", "modelViewMatrix", "texture"], ["position", "color", "texCoord"]);
  }
  return positionColorTextureShader!;
}

ShaderProgram? positionShader;

ShaderProgram getPositionShader() {
  if (positionShader == null) {
    Program? program = makeProgram(positionVertexShader, positionFragmentShader);
    positionShader = ShaderProgram(program!, ["projectionMatrix", "modelViewMatrix", "color"], ["position"]);
  }
  return positionShader!;
}

ShaderProgram? positionColorShader;

ShaderProgram getPositionColorShader() {
  if (positionColorShader == null) {
    Program? program = makeProgram(positionColorVertexShader, positionColorFragmentShader);
    positionColorShader = ShaderProgram(program!, ["projectionMatrix", "modelViewMatrix"], ["position", "color"]);
  }
  return positionColorShader!;
}

ShaderProgram? positionColorRoundingShader;

ShaderProgram getPositionColorRoundingShader() {
  if (positionColorRoundingShader == null) {
    Program? program = makeProgram(positionColorVertexShader, positionColorRoundingFragmentShader);
    positionColorRoundingShader = ShaderProgram(
        program!, ["projectionMatrix", "modelViewMatrix", "midPoint", "rounding", "dimensions", "smoothGradient"], ["position", "color"]);
  }
  return positionColorRoundingShader!;
}

class ShaderProgram {
  Program program;
  List<String> uniformNames;
  Map<String, UniformLocation> uniformLocations = {};
  List<int> attributeLocations = [];
  bool containsProjectionMatrix = false;
  bool containsModelViewMatrix = false;

  ShaderProgram(this.program, this.uniformNames, List<String> attributes) {
    for (String uniformName in uniformNames) {
      UniformLocation uniformLocation = gl.getUniformLocation(program, uniformName);

      uniformLocations[uniformName] = uniformLocation;
    }

    containsProjectionMatrix = uniformNames.contains("projectionMatrix");
    containsModelViewMatrix = uniformNames.contains("modelViewMatrix");

    for (String attributeName in attributes) {
      int attributeLocation = gl.getAttribLocation(program, attributeName);
      if (attributeLocation == -1) {
        consoleLog("Failed to get attribute location for attribute $attributeName");
      }
      attributeLocations.add(attributeLocation);
    }
  }

  void enableAttributes() {
    for (int attributeLocation in attributeLocations) {
      gl.enableVertexAttribArray(attributeLocation);
    }
  }

  void disableAttributes() {
    for (int attributeLocation in attributeLocations) {
      gl.disableVertexAttribArray(attributeLocation);
    }
  }

  void bind() {
    gl.useProgram(program);

    if (containsProjectionMatrix) {
      gl.uniformMatrix4fv(uniformLocations["projectionMatrix"], false, MatrixStack.projectionMatrixStack.getMatrix().getMatrix());
    }

    if (containsModelViewMatrix) {
      gl.uniformMatrix4fv(uniformLocations["modelViewMatrix"], false, MatrixStack.modelViewMatrixStack.getMatrix().getMatrix());
    }
  }
}
