import '../render/matrix_stack.dart';
import '../render/render_util.dart';
import "../main.dart";

import 'click_listener.dart';
import 'segment.dart';

class TimeSegment extends Segment {
  bool playing = false;

  TimeSegment() : super(40) {
    addListener(ClickListener<TimeSegment>((segment) {
      if (overPausePlay()) {
        playing = !playing;
        if (playing) {
          // only cycle if expression was properly passed to vm
          if (uiManager.backPropagate()) {
            audioManager.cycle();
          } else {
            // not playing as failed to back propagate
            playing = false;
          }
        } else {
          audioManager.cycle();
        }
      }
      if (overResetButton()) {
        audioManager.resetTime();
      }
    }));
  }

  @override
  render() {
    super.render();
    if (!playing) {
      renderPlayButton();
    } else {
      renderPauseButton();
    }
    renderResetButton();

    //drawQuad(x + width ~/ 2, y, x + width ~/ 2 + 1, y + 40, 0xFFFFFFFF);
  }

  void renderResetButton() {
    MatrixStack.modelViewMatrixStack.pushMatrix();
    MatrixStack.modelViewMatrixStack.getMatrix().translate(width / 2 + 5, 5, 0.0);

    drawQuad(x, y + 30, x + 30, y, overResetButton() ? 0xFF0000FF : 0xFFFFFFFF);

    MatrixStack.modelViewMatrixStack.popMatrix();
  }

  bool overResetButton() {
    int left = x + width ~/ 2 + 5;
    int right = left + 30;
    int bottom = y + 5;
    int top = bottom + 30;
    return uiManager.lastMouseX > left && uiManager.lastMouseX < right && uiManager.getMouseY() > bottom && uiManager.getMouseY() < top;
  }

  // play button is rendered as two right angled triangles
  void renderPlayButton() {
    int width = 26;
    int height = 15;
    double xOffset = this.width / 2 - 29;
    MatrixStack.modelViewMatrixStack.pushMatrix();
    MatrixStack.modelViewMatrixStack.getMatrix().translate(xOffset, 5, 0.0);
    // lower triangle
    // left bottom, left middle, right middle
    drawTriangle(x, y + height, x, y, x + width, y + height, overPausePlay() ? 0xFF0000FF : 0xFFFFFFFF);
    // upper triangle
    // left bottom, left top, left middle
    drawTriangle(x, y + height, x, y + height * 2, x + width, y + height, overPausePlay() ? 0xFF0000FF : 0xFFFFFFFF);
    MatrixStack.modelViewMatrixStack.popMatrix();
  }

  void renderPauseButton() {
    int height = 30;
    int wid = 10;
    int gap = 2;
    double xOffset = width / 2 - 29;

    MatrixStack.modelViewMatrixStack.pushMatrix();
    MatrixStack.modelViewMatrixStack.getMatrix().translate(xOffset.toDouble(), 5, 0.0);

    drawQuad(x, y + height, x + wid, y, overPausePlay() ? 0xFF0000FF : 0xFFFFFFFF);

    MatrixStack.modelViewMatrixStack.getMatrix().translate(wid + gap * 2, 0.0, 0.0);

    drawQuad(x, y + height, x + wid, y, overPausePlay() ? 0xFF0000FF : 0xFFFFFFFF);

    MatrixStack.modelViewMatrixStack.popMatrix();
  }

  bool overPausePlay() {
    int right = x + width ~/ 2 - 5;
    int left = right - 24;
    int bottom = y + 5;
    int top = bottom + 30;
    return uiManager.lastMouseX > left && uiManager.lastMouseX < right && uiManager.getMouseY() > bottom && uiManager.getMouseY() < top;
  }

  bool overButton() {
    int wid = 10;
    int gap = 2;
    int xOffset = width ~/ 2 - (wid + gap);
    int left = x + xOffset;
    int right = left + wid * 2 + gap * 2;
    return inElement(uiManager.lastMouseX, uiManager.getMouseY()) && uiManager.lastMouseX > left && uiManager.lastMouseX < right;
  }

  set setPlaying(bool playing) => this.playing = playing;

  static TimeSegment fromMap(data) {
    return TimeSegment();
  }

  @override
  Map toMap() {
    return {};
  }
}
