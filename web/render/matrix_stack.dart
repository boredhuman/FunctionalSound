import '../util/mat4.dart';

class MatrixStack {
  static MatrixStack projectionMatrixStack = MatrixStack();
  static MatrixStack modelViewMatrixStack = MatrixStack();

  List<Mat4> stack = [Mat4()];
  int index = 0;

  Mat4 getMatrix() {
    return stack[index];
  }

  void pushMatrix() {
    stack.add(getMatrix().clone());
    index++;
  }

  void popMatrix() {
    stack.removeLast();
    index--;
  }
}
