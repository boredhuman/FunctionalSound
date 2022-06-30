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
    int xOffset = width ~/ 2 - 12;

    drawQuad(x + xOffset, y + height + yOffset, x + 10 + xOffset, y + yOffset, 0xFFFFFFFF);

    xOffset = width ~/ 2 + 2;
    drawQuad(x + xOffset, y + height + yOffset, x + 10 + xOffset, y + yOffset, 0xFFFFFFFF);
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
