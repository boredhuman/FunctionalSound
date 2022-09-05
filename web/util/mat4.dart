import 'package:js/js.dart';
import 'util.dart';

@JS("glMatrix.mat4.create")
external Object mat4Create();

@JS("glMatrix.mat4.translate")
external Object mat4Translate(Object matIn, Object matOut, Object vector3);

@JS("glMatrix.mat4.scale")
external Object mat4Scale(Object matIn, Object matOut, Object vector3);

@JS("glMatrix.mat4.rotateX")
external Object mat4RotateX(Object matIn, Object matOut, double angleXRadians);

@JS("glMatrix.mat4.rotateY")
external Object mat4RotateY(Object matIn, Object matOut, double angleYRadians);

@JS("glMatrix.mat4.rotateZ")
external Object mat4RotateZ(Object matIn, Object matOut, double angleZRadians);

@JS("glMatrix.mat4.ortho")
external Object mat4Ortho(Object matIn, num left, num right, num bottom, num top, num near, num far);

@JS("glMatrix.mat4.mul")
external Object mat4Mul(Object receivingMat, Object matLeft, Object matRight);

@JS("glMatrix.vec4.transformMat4")
external Object vec4transformMat4(Object receivingVec4, Object vec4, Object mat4);

@JS("glMatrix.mat4.copy")
external Object copy(Object receivingMat, Object srcMat);

@JS("glMatrix.mat4.identity")
external void mat4Identity(Object receivingMat);

class Mat4 {
  Object matrix;

  Mat4() : matrix = mat4Create();

  void scale(double x, double y, double z) {
    mat4Scale(matrix, matrix, [x, y, z]);
  }

  void translate(double x, double y, double z) {
    mat4Translate(matrix, matrix, [x, y, z]);
  }

  void rotateX(double angle) {
    mat4RotateX(matrix, matrix, toRadians(angle));
  }

  void rotateY(double angle) {
    mat4RotateY(matrix, matrix, toRadians(angle));
  }

  void rotateZ(double angle) {
    mat4RotateZ(matrix, matrix, toRadians(angle));
  }

  transform(List<double> vec4) {
    return vec4transformMat4(vec4, vec4, matrix);
  }

  Object getMatrix() {
    return matrix;
  }

  void orthogonalMat(num left, num right, num bottom, num top, num near, num far) {
    mat4Ortho(matrix, left, right, bottom, top, near, far);
  }

  void mul(Mat4 right) {
    mat4Mul(matrix, matrix, right);
  }

  void identity() {
    mat4Identity(matrix);
  }

  Mat4 clone() {
    Mat4 copyMat = Mat4();
    copyMat.matrix = copy(copyMat.matrix, matrix);
    return copyMat;
  }
}

