import 'dart:html';
import 'dart:web_gl';
import 'sound/audio_manager.dart';
import 'render/font_renderer.dart';
import 'render/matrix_stack.dart';
import 'ui_manager.dart';
import 'render/buffer_builder.dart';
import 'render/font_atlas.dart';
import 'util/util.dart';

RenderingContext gl = setupWebGL();
FontTexture fontTexture = FontTexture();
FontRenderer? fontRenderer;
BufferBuilder bufferBuilder = BufferBuilder();
late UIManager uiManager;
MatrixStack matrixStack = MatrixStack();
AudioManager audioManager = AudioManager();

void main() {
  fontRenderer = FontRenderer(fontTexture);
  uiManager = UIManager(document.getElementById("canvas") as CanvasElement);
  audioManager.init();
  renderLoop();
}

void renderLoop() {
  CanvasElement canvas = document.getElementById("canvas") as CanvasElement;
  MatrixStack.projectionMatrixStack.pushMatrix();
  MatrixStack.projectionMatrixStack.getMatrix().orthogonalMat(0, canvas.clientWidth, 0, canvas.clientHeight, -10, 10);

  gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

  uiManager.render();
  MatrixStack.projectionMatrixStack.popMatrix();

  int error;

  while ((error = gl.getError()) != WebGL.NO_ERROR) {
    consoleLog("Got error: $error");
  }

  window.requestAnimationFrame((highResTime) {
    renderLoop();
  });
}

RenderingContext setupWebGL() {
  CanvasElement canvas = document.getElementById("canvas") as CanvasElement;

  RenderingContext renderingContext = canvas.getContext("webgl") as RenderingContext;

  return renderingContext;
}
