import 'package:js/js.dart';
import 'dart:math' as math;

import '../main.dart';

@JS("console.log")
external void consoleLog(Object? object);

bool overCross(int x, int y, int width) {
  int mouseX = uiManager.getMouseX();
  int mouseY = uiManager.getMouseY();
  int half = width ~/ 2;
  return mouseX > x - half && mouseY > y - half && mouseX < x + half && mouseY < y + half;
}

double toRadians(double degrees) {
  return degrees * math.pi / 180;
}