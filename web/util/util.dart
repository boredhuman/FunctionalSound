import 'package:js/js.dart';
import 'dart:math' as math;

@JS("console.log")
external void consoleLog(Object object);

double toRadians(double degrees) {
  return degrees * math.pi / 180;
}