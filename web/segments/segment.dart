import 'dart:html';

import 'nodes.dart';

abstract class Segment {
  int height;
  bool inputSegment;
  int x = 0;
  int y = 0;
  int width = 0;
  Node? parent;

  bool inElement(int xPos, int yPos) {
    return xPos > x && yPos > y && xPos < x + width && yPos < y + height;
  }

  Segment(this.height, {this.inputSegment = false});

  render();

  // return true to prevent passing event
  bool handleEvent(Event event) {
    return false;
  }

  bool isOver() {
    return false;
  }
}
