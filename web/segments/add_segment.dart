import 'dart:html';

import '../render/render_util.dart';
import "../main.dart";
import 'expression_segment.dart';
import 'input_segment.dart';
import 'segment.dart';

class AddSegment extends Segment {
  bool forExpressionSegment = true;

  AddSegment({this.forExpressionSegment = true}) : super(50);

  @override
  render() {
    int mouseY = uiManager.getMouseY();

    if (forExpressionSegment) {
      int color = overCross(x + width ~/ 2, y + height ~/ 2, 30, uiManager.lastMouseX, mouseY) ? 0xFF0000FF : 0xFFFFFFFF;
      drawCross(x + width ~/ 2, y + height ~/ 2, 30, color);
    } else {
      int color = overCross(x + 20, y + height ~/ 2, 21, uiManager.lastMouseX, mouseY) ? 0xFF0000FF : 0xFFFFFFFF;
      // left cross
      drawCross(x + 20, y + height ~/ 2, 21, color);
      int bottomPad = (height - 32) ~/ 2;
      drawString("Add Input", x + 40, y + bottomPad, 0xFFFFFFFF);
    }
  }

  bool overCross(int x, int y, int width, int mouseX, int mouseY) {
    int half = width ~/ 2;
    return mouseX > x - half && mouseY > y - half && mouseX < x + half && mouseY < y + half;
  }

  bool over() {
    int mouseY = uiManager.getMouseY();

    return overCross(x + width ~/ 2, y + height ~/ 2, 30, uiManager.lastMouseX, mouseY);
  }

  @override
  bool handleEvent(Event event) {
    if (event is MouseEvent) {
      if (handleMouseEvent(event)) {
        return true;
      }
    }
    return false;
  }

  bool handleMouseEvent(MouseEvent event) {
    if (over() && forExpressionSegment) {
      parent!.removeSegment(this);
      parent!.addQueue.add(ExpressionSegment());
      parent!.addQueue.add(AddSegment(forExpressionSegment: false));
      print('Consuming click');
      return true;
    }

    int mouseY = uiManager.getMouseY();
    bool overLeftCross = overCross(x + 20, y + height ~/ 2, 21, uiManager.lastMouseX, mouseY);
    if (overLeftCross && !forExpressionSegment) {
      parent!.removeSegment(this);
      int index = 0;
      for (Segment segment in parent!.segments) {
        if (segment is InputSegment) {
          index++;
        }
      }
      parent!.addQueue.add(InputSegment(index));
      parent!.addQueue.add(this);

      return true;
    }
    return false;
  }
}
