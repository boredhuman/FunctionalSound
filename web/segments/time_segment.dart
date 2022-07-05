import '../render/render_util.dart';
import "../main.dart";
import "dart:html";

import 'segment.dart';

class TimeSegment extends Segment {
  Function? onclick;
  bool playing = false;

  TimeSegment() : super(40);

  @override
  render() {
    if (playing) {
      renderPlayButton();
    } else {
      renderPauseButton();
    }
  }

  void renderPlayButton() {
    int height = 15;
    int yOffset = 5;
    int xOffset = width ~/ 2 - 15 + height ~/ 2;
    drawTriangle(x + xOffset, y + height + yOffset, x + xOffset, y + yOffset, x + height + xOffset, y + height + yOffset, 0xFFFFFFFF);
    drawTriangle(x + xOffset, y + height + yOffset, x + xOffset, y + height * 2 + yOffset, x + height + xOffset, y + height + yOffset, 0xFFFFFFFF);
  }

  void renderPauseButton() {
    int height = 30;
    int yOffset = 5;
    int wid = 10;
    int gap = 2;
    int xOffset = width ~/ 2 - (wid + gap);

    drawQuad(x + xOffset, y + height + yOffset, x + wid + xOffset, y + yOffset, overButton() ? 0xFF0000FF : 0xFFFFFFFF);

    xOffset += wid + gap * 2;
    drawQuad(x + xOffset, y + height + yOffset, x + wid + xOffset, y + yOffset, overButton() ? 0xFF0000FF : 0xFFFFFFFF);
  }

  bool overButton() {
    int wid = 10;
    int gap = 2;
    int xOffset = width ~/ 2 - (wid + gap);
    int left = x + xOffset;
    int right = left + wid * 2 + gap * 2;
    return inElement(uiManager.lastMouseX, uiManager.getMouseY()) && uiManager.lastMouseX > left && uiManager.lastMouseX < right;
  }

  @override
  bool handleEvent(Event event) {
    if (!inElement(uiManager.lastMouseX, uiManager.getMouseY())) {
      return false;
    }
    if (event is MouseEvent && onclick != null) {
      playing = !playing;
      onclick!.call();
    }
    return false;
  }
}
